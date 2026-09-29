"""Observe an exported Godot game in real Chrome through its packaged launcher.

Requires the locally available playwright package and Chrome; installs nothing.
The default run captures the loaded entry screen, console and network results.
Optional JSON steps replay coordinates ONLY after they have been observed at
1440x900. Captures still require visual review; assert_save checks only persisted
fields, without modifying the isolated browser context's localStorage.
"""

from __future__ import annotations

import argparse
from datetime import datetime, timezone
import json
from pathlib import Path
import re
import subprocess
import sys
import time
import traceback
from urllib.parse import urlparse

from playwright.sync_api import sync_playwright


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_CHROME = Path(r"C:\Program Files\Google\Chrome\Application\chrome.exe")
SAVE_STORAGE_KEY = "last-outpost:user://last_outpost_station_v1.json"


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser(description=__doc__)
    result.add_argument("--launcher", type=Path, default=ROOT / "build/LastOutpostLauncher.exe")
    result.add_argument("--chrome", type=Path, default=DEFAULT_CHROME)
    result.add_argument("--output", type=Path, default=ROOT / "build/web-smoke")
    result.add_argument("--steps", type=Path, help="Observed UI actions as a JSON array; see module docstring.")
    result.add_argument("--timeout-ms", type=int, default=90000)
    return result


def load_steps(path: Path | None) -> list[dict]:
    if path is None:
        return []
    data = json.loads(path.read_text(encoding="utf-8-sig"))
    if not isinstance(data, list):
        raise ValueError("The steps file must be a JSON array.")
    for step in data:
        if not isinstance(step, dict) or step.get("action") not in {"click", "key", "hold", "reload", "capture", "wait", "assert_save"}:
            raise ValueError("Supported actions: click, key, hold, reload, capture, wait, assert_save.")
        if "capture" in step and not re.fullmatch(r"[A-Za-z0-9_-]+", step["capture"]):
            raise ValueError("Capture names accept only letters, digits, underscores and hyphens.")
        if step["action"] == "click" and not (0 <= step["x"] < 1440 and 0 <= step["y"] < 900):
            raise ValueError("Click coordinates must be inside the 1440x900 viewport.")
        if not 0 <= step.get("wait_ms", 250) <= 10000:
            raise ValueError("Each real-time wait must be between 0 and 10000 ms.")
        if step["action"] == "hold" and not 0 < step.get("duration_ms", 500) <= 10000:
            raise ValueError("Each key hold must be between 1 and 10000 ms.")
        if step["action"] == "assert_save":
            expected = step.get("expected")
            if not isinstance(expected, dict) or not expected or not all(isinstance(field, str) and field for field in expected):
                raise ValueError("assert_save requires a nonempty expected object with named fields.")
            if not isinstance(step.get("storage_key", SAVE_STORAGE_KEY), str) or not step.get("storage_key", SAVE_STORAGE_KEY):
                raise ValueError("assert_save storage_key must be a nonempty string.")
    return data


def assert_saved_fields(page, step: dict, index: int, report: dict) -> None:
    """Read and compare a snapshot without mutating storage or the game state."""
    key = step.get("storage_key", SAVE_STORAGE_KEY)
    expected = step["expected"]
    assertion = {
        "step": index,
        "label": step.get("label", "assert_save"),
        "storage_key": key,
        "expected": expected,
        "observed": {},
        "passed": False,
    }
    report["save_assertions"].append(assertion)
    try:
        raw = page.evaluate("key => window.localStorage.getItem(key)", key)
        if raw is None:
            raise AssertionError("No persisted save found at " + key)
        snapshot = json.loads(raw)
        if not isinstance(snapshot, dict):
            raise AssertionError("The persisted save is not a JSON object.")
        assertion["observed"] = {field: snapshot.get(field) for field in expected}
        assertion["missing_fields"] = [field for field in expected if field not in snapshot]
        assertion["mismatched_fields"] = [field for field, value in expected.items() if field in snapshot and snapshot[field] != value]
        if assertion["missing_fields"] or assertion["mismatched_fields"]:
            raise AssertionError("Persisted save differs: expected " + json.dumps(expected, ensure_ascii=False) + "; observed " + json.dumps(assertion["observed"], ensure_ascii=False))
        assertion["passed"] = True
    except Exception as error:
        assertion["error"] = str(error)
        raise


def wait_for_game(page, timeout_ms: int) -> None:
    # The default Godot HTML shell removes #status only after startGame resolves.
    # Canvas presence alone can still be a splash or a failed initialization.
    page.wait_for_function(
        """() => !document.getElementById('status') &&
        document.getElementById('canvas')?.width > 0 &&
        document.getElementById('canvas')?.height > 0""",
        timeout=timeout_ms,
    )
    # Wait on real animation frames; no virtual time / fast-forward flags.
    page.evaluate("""() => new Promise(resolve => {
        let remaining = 12;
        function frame() { if (--remaining <= 0) resolve(); else requestAnimationFrame(frame); }
        requestAnimationFrame(frame);
    })""")


def run(args) -> int:
    args.launcher = args.launcher.resolve()
    args.chrome = args.chrome.resolve()
    args.output = args.output.resolve()
    for path in [args.launcher, args.chrome]:
        if not path.is_file():
            raise FileNotFoundError(path)
    if not 1000 <= args.timeout_ms <= 180000:
        raise ValueError("--timeout-ms must be between 1000 and 180000.")
    steps = load_steps(args.steps)
    args.output.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
    readiness = args.output / ("server-" + stamp + ".txt")
    report = {
        "started_utc": stamp,
        "launcher": str(args.launcher),
        "chrome": str(args.chrome),
        "viewport": {"width": 1440, "height": 900},
        "loaded": False,
        "console": [],
        "page_errors": [],
        "network_errors": [],
        "captures": [],
        "actions": [],
        "save_assertions": [],
        "runtime_checks_passed": False,
        "visual_review_required": True,
    }
    startup = subprocess.STARTUPINFO()
    startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
    startup.wShowWindow = subprocess.SW_HIDE
    server = subprocess.Popen(
        [str(args.launcher), "--serve-test", str(readiness), "300"],
        cwd=args.launcher.parent,
        startupinfo=startup,
        creationflags=subprocess.CREATE_NO_WINDOW,
    )
    outcome = 1
    try:
        deadline = time.monotonic() + 10
        while not readiness.is_file():
            if server.poll() is not None:
                raise RuntimeError("Launcher server exited before readiness: " + str(server.returncode))
            if time.monotonic() >= deadline:
                raise TimeoutError("Launcher did not write its URL within 10 seconds.")
            time.sleep(0.05)
        url = readiness.read_text(encoding="ascii").strip()
        address = urlparse(url)
        if address.scheme != "http" or address.hostname != "127.0.0.1" or address.port != 18747:
            raise RuntimeError("Unexpected launcher origin: " + url)
        report["url"] = url
        with sync_playwright() as playwright:
            browser = playwright.chromium.launch(
                executable_path=str(args.chrome),
                headless=True,
                args=["--use-angle=swiftshader", "--enable-unsafe-swiftshader"],
            )
            # A temporary browser context preserves the player's actual saves.
            context = browser.new_context(viewport=report["viewport"], device_scale_factor=1, locale="fr-FR")
            page = context.new_page()
            page.on("console", lambda message: report["console"].append({"type": message.type, "text": message.text}))
            page.on("pageerror", lambda error: report["page_errors"].append(str(error)))
            page.on("requestfailed", lambda request: report["network_errors"].append({"url": request.url, "failure": request.failure}))
            page.on("response", lambda response: report["network_errors"].append({"url": response.url, "status": response.status}) if response.status >= 400 else None)
            try:
                page.goto(url, wait_until="domcontentloaded", timeout=args.timeout_ms)
                wait_for_game(page, args.timeout_ms)
                report["loaded"] = True

                def capture(name: str) -> None:
                    destination = args.output / (name + ".png")
                    page.screenshot(path=str(destination), full_page=True)
                    report["captures"].append(str(destination))

                capture("01-entry")
                for index, step in enumerate(steps, start=1):
                    action = step["action"]
                    if action == "click":
                        page.mouse.click(step["x"], step["y"])
                    elif action == "key":
                        page.keyboard.press(step["key"])
                    elif action == "hold":
                        page.keyboard.down(step["key"])
                        try:
                            page.wait_for_timeout(step.get("duration_ms", 500))
                        finally:
                            page.keyboard.up(step["key"])
                    elif action == "reload":
                        page.reload(wait_until="domcontentloaded", timeout=args.timeout_ms)
                        wait_for_game(page, args.timeout_ms)
                    elif action == "assert_save":
                        assert_saved_fields(page, step, index, report)
                    page.wait_for_timeout(step.get("wait_ms", 250))
                    report["actions"].append(step)
                    if "capture" in step or action == "capture":
                        capture(step.get("capture", "step-" + str(index)))
                capture("99-final")
                report["canvas"] = page.locator("#canvas").evaluate("element => ({width: element.width, height: element.height})")
                errors = [entry for entry in report["console"] if entry["type"] == "error" or "SCRIPT ERROR" in entry["text"] or "Parse Error:" in entry["text"]]
                report["runtime_checks_passed"] = not errors and not report["page_errors"] and not report["network_errors"]
                outcome = 0 if report["runtime_checks_passed"] else 1
            except Exception:
                try:
                    page.screenshot(path=str(args.output / "failure.png"), full_page=True)
                except Exception:
                    pass
                raise
            finally:
                context.close()
                browser.close()
    except Exception as error:
        report["exception"] = str(error)
        report["traceback"] = traceback.format_exc()
    finally:
        if server.poll() is None:
            server.terminate()
            try:
                server.wait(timeout=5)
            except subprocess.TimeoutExpired:
                server.kill()
                server.wait(timeout=5)
        report["server_process_stopped"] = server.poll() is not None
        (args.output / "report.json").write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps({"exit_code": outcome, "loaded": report["loaded"], "captures": report["captures"], "report": str(args.output / "report.json"), "visual_review_required": True}, ensure_ascii=False))
    return outcome


if __name__ == "__main__":
    sys.exit(run(parser().parse_args()))
