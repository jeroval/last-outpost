using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Net;
using System.Net.Sockets;
using System.Text;
using System.Threading;
using System.Windows.Forms;

namespace LastOutpostLauncher
{
    internal static class Program
    {
        [STAThread]
        private static int Main(string[] args)
        {
            string root = AppDomain.CurrentDomain.BaseDirectory;
            if (args.Length >= 2 && args[0] == "--self-test")
                return SelfTest.Run(args[1]);
            if (args.Length >= 2 && args[0] == "--diagnose")
            {
                File.WriteAllText(args[1], new GamePaths(root).Describe(), Encoding.UTF8);
                return new GamePaths(root).HasWindows || new GamePaths(root).HasWeb ? 0 : 2;
            }
            if (args.Length >= 3 && args[0] == "--serve-test")
            {
                int seconds;
                if (!int.TryParse(args[2], out seconds) || seconds < 1 || seconds > 300) return 3;
                if (!new GamePaths(root).HasWeb) { File.WriteAllText(args[1], "Web export missing"); return 2; }
                using (LocalWebServer server = new LocalWebServer(new GamePaths(root).WebRoot))
                {
                    File.WriteAllText(args[1], server.Url, Encoding.ASCII);
                    Thread.Sleep(seconds * 1000);
                }
                return 0;
            }
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            using (LauncherForm form = new LauncherForm(new GamePaths(root)))
            {
                if (args.Length >= 2 && args[0] == "--preview")
                {
                    form.Show();
                    Application.DoEvents();
                    using (Bitmap bitmap = new Bitmap(form.Width, form.Height))
                    {
                        form.DrawToBitmap(bitmap, new Rectangle(Point.Empty, form.Size));
                        bitmap.Save(args[1], System.Drawing.Imaging.ImageFormat.Png);
                    }
                    return 0;
                }
                Application.Run(form);
            }
            return 0;
        }
    }

    internal sealed class GamePaths
    {
        internal readonly string Root;
        internal readonly string WindowsExe;
        internal readonly string WebRoot;
        internal readonly string Saves;
        internal GamePaths(string root)
        {
            Root = Path.GetFullPath(root);
            WindowsExe = Path.Combine(Root, "windows", "LastOutpost.exe");
            WebRoot = Path.Combine(Root, "web");
            Saves = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), "Godot", "app_userdata", "Last Outpost");
        }
        internal bool HasWindows { get { return File.Exists(WindowsExe); } }
        internal bool HasWeb
        {
            get
            {
                foreach (string name in new string[] { "index.html", "index.js", "index.wasm", "index.pck" })
                    if (!File.Exists(Path.Combine(WebRoot, name)) || new FileInfo(Path.Combine(WebRoot, name)).Length == 0) return false;
                return true;
            }
        }
        internal string Describe()
        {
            return "Last Outpost Launcher 1.0\r\nWindows: " + (HasWindows ? "READY" : "MISSING") + "\r\nWeb: " + (HasWeb ? "READY" : "MISSING") + "\r\nRoot: " + Root + "\r\nSaves: " + Saves + "\r\n";
        }
    }

    internal sealed class LauncherForm : Form
    {
        private readonly GamePaths paths;
        private readonly Label status;
        private LocalWebServer server;
        private readonly Color cream = Color.FromArgb(237, 234, 222);
        internal LauncherForm(GamePaths gamePaths)
        {
            paths = gamePaths;
            Text = "Last Outpost";
            ClientSize = new Size(740, 550);
            MinimumSize = MaximumSize = Size;
            FormBorderStyle = FormBorderStyle.FixedSingle;
            MaximizeBox = false;
            StartPosition = FormStartPosition.CenterScreen;
            BackColor = Color.FromArgb(21, 37, 39);
            ForeColor = cream;
            Font = new Font("Segoe UI", 10F);
            AutoScaleMode = AutoScaleMode.Dpi;

            Label tag = TextLabel("SURVIVRE. RÉPARER. ACCUEILLIR.", 36, 28, 668, 25, 10F);
            tag.ForeColor = Color.FromArgb(219, 167, 94);
            TextLabel("LAST OUTPOST", 33, 61, 680, 66, 34F, FontStyle.Bold);
            TextLabel("Une station oubliée. Votre prochain refuge.", 36, 128, 668, 29, 14F);
            TextLabel("Explorez les environs, rapportez des ressources et redonnez vie à votre station.", 36, 178, 658, 48, 11F);

            Button windows = ActionButton("Jouer sur Windows", 36, 245, 322, 61, true);
            windows.AccessibleDescription = "Lance le jeu installé dans ce dossier.";
            windows.Click += delegate { StartWindows(); };
            Button web = ActionButton("Jouer dans le navigateur", 376, 245, 328, 61, false);
            web.AccessibleDescription = "Ouvre le jeu localement dans votre navigateur. Gardez ce lanceur ouvert.";
            web.Click += delegate { StartWeb(); };
            TextLabel(paths.HasWindows ? "Le choix conseillé sur ce PC" : "Version Windows absente du dossier", 36, 316, 322, 32, 9F);
            TextLabel(paths.HasWeb ? "Gardez le lanceur ouvert pendant la partie" : "Version navigateur absente du dossier", 376, 316, 328, 35, 9F);

            status = TextLabel("Prêt à retrouver la route.", 36, 376, 668, 57, 10F);
            status.ForeColor = Color.FromArgb(146, 202, 183);
            Button help = ActionButton("Comment jouer", 36, 458, 202, 43, false);
            help.Click += delegate { ShowHelp(); };
            Button saves = ActionButton("Mes sauvegardes", 254, 458, 220, 43, false);
            saves.Click += delegate { OpenSaves(); };
            Button folder = ActionButton("Dossier du jeu", 490, 458, 214, 43, false);
            folder.Click += delegate { OpenPath(paths.Root); };
            AcceptButton = windows;
            FormClosed += delegate { if (server != null) server.Dispose(); };
        }
        private Label TextLabel(string text, int x, int y, int width, int height, float size, FontStyle style = FontStyle.Regular)
        {
            Label label = new Label { Text = text, Location = new Point(x, y), Size = new Size(width, height), Font = new Font("Segoe UI", size, style), ForeColor = cream };
            Controls.Add(label);
            return label;
        }
        private Button ActionButton(string text, int x, int y, int width, int height, bool primary)
        {
            Button button = new Button { Text = text, Location = new Point(x, y), Size = new Size(width, height), FlatStyle = FlatStyle.Flat, Cursor = Cursors.Hand, Font = new Font("Segoe UI", 11F, primary ? FontStyle.Bold : FontStyle.Regular), BackColor = primary ? Color.FromArgb(220, 171, 99) : Color.FromArgb(38, 61, 62), ForeColor = primary ? Color.FromArgb(21, 37, 39) : cream };
            button.FlatAppearance.BorderColor = primary ? Color.FromArgb(220, 171, 99) : Color.FromArgb(79, 107, 104);
            button.FlatAppearance.BorderSize = 1;
            Controls.Add(button);
            return button;
        }
        private void StartWindows()
        {
            if (!paths.HasWindows)
            {
                ShowProblem("Le jeu Windows n'est pas présent.", "Extrayez toute l'archive du jeu dans un même dossier.\r\n\r\nPour reconstruire depuis les sources : scripts\\export-windows.ps1.");
                return;
            }
            try
            {
                Process.Start(new ProcessStartInfo(paths.WindowsExe) { WorkingDirectory = Path.GetDirectoryName(paths.WindowsExe), UseShellExecute = true });
                status.Text = "Le jeu Windows est lancé. Vous pouvez fermer ce lanceur.";
            }
            catch (Exception error) { ShowProblem("Le jeu n'a pas pu démarrer.", error.Message); }
        }
        private void StartWeb()
        {
            if (!paths.HasWeb)
            {
                ShowProblem("Le jeu navigateur n'est pas présent.", "Utilisez l'archive complète avec son dossier web.\r\n\r\nPour reconstruire depuis les sources : scripts\\export-web.ps1.");
                return;
            }
            try
            {
                if (server == null) server = new LocalWebServer(paths.WebRoot);
                Process.Start(new ProcessStartInfo(server.Url) { UseShellExecute = true });
                status.Text = "Jeu ouvert dans le navigateur. Gardez cette fenêtre ouverte jusqu'à la fin de votre partie.";
            }
            catch (SocketException) { ShowProblem("Le navigateur n'a pas pu démarrer.", "Le port local 18747 est déjà occupé. Fermez l'autre lanceur Last Outpost s'il est ouvert, puis réessayez. Vous pouvez aussi jouer sur Windows."); }
            catch (Exception error) { ShowProblem("Le navigateur n'a pas pu démarrer.", error.Message); }
        }
        private void OpenSaves()
        {
            if (Directory.Exists(paths.Saves)) OpenPath(paths.Saves);
            else MessageBox.Show(this, "Votre dossier de sauvegardes Windows apparaîtra après votre première partie.\r\n\r\nLa version navigateur conserve ses sauvegardes dans ce navigateur, séparément de Windows.", "Mes sauvegardes", MessageBoxButtons.OK, MessageBoxIcon.Information);
        }
        private void OpenPath(string path)
        {
            try { Process.Start(new ProcessStartInfo(path) { UseShellExecute = true }); }
            catch (Exception error) { ShowProblem("Impossible d'ouvrir ce dossier.", error.Message); }
        }
        private void ShowHelp()
        {
            MessageBox.Show(this, "Commencez par rejoindre le garage et ramener des matériaux à la station. Les objectifs et commandes sont indiqués dans le jeu.\r\n\r\nWindows : les sauvegardes sont conservées sur ce PC.\r\nNavigateur : gardez le lanceur ouvert ; vos sauvegardes restent dans le navigateur utilisé.\r\n\r\nAucun compte, aucune connexion Internet et aucun éditeur Godot ne sont nécessaires. Pour déplacer le jeu, copiez son dossier complet.", "Bienvenue à Last Outpost", MessageBoxButtons.OK, MessageBoxIcon.Information);
        }
        private void ShowProblem(string title, string detail)
        {
            status.Text = title;
            MessageBox.Show(this, detail, title, MessageBoxButtons.OK, MessageBoxIcon.Information);
        }
    }

    // A loopback-only server avoids URL reservations, installation and administrator rights.
    internal sealed class LocalWebServer : IDisposable
    {
        private readonly string root;
        private readonly TcpListener listener;
        private readonly Thread thread;
        private readonly List<TcpClient> clients = new List<TcpClient>();
        private volatile bool stopped;
        internal readonly string Url;
        internal readonly int Port;
        internal LocalWebServer(string webRoot, int requestedPort = 18747)
        {
            root = Path.GetFullPath(webRoot).TrimEnd(Path.DirectorySeparatorChar) + Path.DirectorySeparatorChar;
            if (!Directory.Exists(root)) throw new DirectoryNotFoundException("Dossier web absent.");
            // A stable origin keeps IndexedDB saves available between launches.
            listener = new TcpListener(IPAddress.Loopback, requestedPort);
            listener.Start(16);
            Port = ((IPEndPoint)listener.LocalEndpoint).Port;
            Url = "http://127.0.0.1:" + Port + "/";
            thread = new Thread(AcceptLoop) { IsBackground = true, Name = "Last Outpost local web" };
            thread.Start();
        }
        private void AcceptLoop()
        {
            while (!stopped)
            {
                TcpClient client;
                try { client = listener.AcceptTcpClient(); }
                catch (SocketException) { if (stopped) return; continue; }
                catch (ObjectDisposedException) { return; }
                lock (clients)
                {
                    if (stopped || clients.Count >= 24) { client.Close(); continue; }
                    clients.Add(client);
                }
                ThreadPool.QueueUserWorkItem(delegate { Serve(client); });
            }
        }
        private void Serve(TcpClient client)
        {
            try
            {
                client.ReceiveTimeout = 4000;
                client.SendTimeout = 10000;
                using (NetworkStream stream = client.GetStream())
                {
                    byte[] headerBytes = new byte[16384];
                    int count = 0;
                    while (count < headerBytes.Length)
                    {
                        int value = stream.ReadByte();
                        if (value < 0) return;
                        headerBytes[count++] = (byte)value;
                        if (count >= 4 && headerBytes[count - 4] == 13 && headerBytes[count - 3] == 10 && headerBytes[count - 2] == 13 && headerBytes[count - 1] == 10) break;
                    }
                    if (count == headerBytes.Length) { Error(stream, 431, "Request Header Fields Too Large"); return; }
                    string[] lines = Encoding.ASCII.GetString(headerBytes, 0, count).Split(new string[] { "\r\n" }, StringSplitOptions.None);
                    string[] request = lines[0].Split(' ');
                    if (request.Length != 3 || !request[2].StartsWith("HTTP/1.")) { Error(stream, 400, "Bad Request"); return; }
                    if (request[0] != "GET" && request[0] != "HEAD") { Error(stream, 405, "Method Not Allowed"); return; }
                    string host = "";
                    foreach (string line in lines)
                        if (line.StartsWith("Host:", StringComparison.OrdinalIgnoreCase)) host = line.Substring(5).Trim();
                    if (host != "127.0.0.1:" + Port) { Error(stream, 403, "Forbidden"); return; }
                    string path = ResolvePath(request[1]);
                    if (path == null) { Error(stream, 403, "Forbidden"); return; }
                    if (!File.Exists(path)) { Error(stream, 404, "Not Found"); return; }
                    using (FileStream file = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.Read))
                    {
                        Header(stream, 200, "OK", file.Length, MimeType(path));
                        if (request[0] != "HEAD") file.CopyTo(stream);
                    }
                }
            }
            catch (IOException) { }
            catch (SocketException) { }
            catch (ObjectDisposedException) { }
            catch (UnauthorizedAccessException) { }
            finally { client.Close(); lock (clients) { clients.Remove(client); } }
        }
        private string ResolvePath(string target)
        {
            try
            {
                if (target.Length > 2048 || !target.StartsWith("/")) return null;
                string decoded = Uri.UnescapeDataString(target.Split('?')[0]);
                if (decoded.IndexOf('\\') >= 0 || decoded.IndexOf(':') >= 0 || decoded.IndexOf('\0') >= 0) return null;
                foreach (string segment in decoded.Split('/')) if (segment == ".." || segment == ".") return null;
                if (decoded == "/") decoded = "/index.html";
                string path = Path.GetFullPath(Path.Combine(root, decoded.TrimStart('/').Replace('/', Path.DirectorySeparatorChar)));
                if (!path.StartsWith(root, StringComparison.OrdinalIgnoreCase)) return null;
                string current = path;
                while (current.Length >= root.TrimEnd(Path.DirectorySeparatorChar).Length)
                {
                    if ((File.Exists(current) || Directory.Exists(current)) && (File.GetAttributes(current) & FileAttributes.ReparsePoint) != 0) return null;
                    current = Path.GetDirectoryName(current);
                    if (current == null) break;
                }
                return path;
            }
            catch (ArgumentException) { return null; }
            catch (UriFormatException) { return null; }
            catch (NotSupportedException) { return null; }
            catch (PathTooLongException) { return null; }
        }
        private static string MimeType(string path)
        {
            switch (Path.GetExtension(path).ToLowerInvariant())
            {
                case ".html": return "text/html; charset=utf-8";
                case ".js": return "text/javascript; charset=utf-8";
                case ".wasm": return "application/wasm";
                case ".json": return "application/json; charset=utf-8";
                case ".css": return "text/css; charset=utf-8";
                case ".svg": return "image/svg+xml";
                case ".png": return "image/png";
                case ".ico": return "image/x-icon";
                default: return "application/octet-stream";
            }
        }
        private static void Header(NetworkStream stream, int code, string reason, long size, string type)
        {
            string value = "HTTP/1.1 " + code + " " + reason + "\r\nContent-Length: " + size + "\r\nContent-Type: " + type + "\r\nConnection: close\r\nCache-Control: no-store\r\nX-Content-Type-Options: nosniff\r\nCross-Origin-Opener-Policy: same-origin\r\nCross-Origin-Embedder-Policy: require-corp\r\n\r\n";
            byte[] bytes = Encoding.ASCII.GetBytes(value);
            stream.Write(bytes, 0, bytes.Length);
        }
        private static void Error(NetworkStream stream, int code, string reason)
        {
            byte[] bytes = Encoding.UTF8.GetBytes(reason);
            Header(stream, code, reason, bytes.Length, "text/plain; charset=utf-8");
            stream.Write(bytes, 0, bytes.Length);
        }
        public void Dispose()
        {
            if (stopped) return;
            stopped = true;
            listener.Stop();
            lock (clients) { foreach (TcpClient client in clients) client.Close(); }
            thread.Join(1000);
        }
    }

    internal static class SelfTest
    {
        internal static int Run(string reportPath)
        {
            StringBuilder report = new StringBuilder();
            string fixture = Path.Combine(Path.GetTempPath(), "Last Outpost launcher " + Guid.NewGuid().ToString("N"));
            int result = 1;
            try
            {
                string web = Path.Combine(fixture, "web");
                Directory.CreateDirectory(web);
                Directory.CreateDirectory(Path.Combine(web, "space folder"));
                File.WriteAllText(Path.Combine(web, "index.html"), "OUTPOST_WEB_FIXTURE", Encoding.ASCII);
                File.WriteAllText(Path.Combine(web, "index.wasm"), "WASM_FIXTURE", Encoding.ASCII);
                File.WriteAllText(Path.Combine(web, "space folder", "file.txt"), "WITH_SPACES", Encoding.ASCII);
                File.WriteAllText(Path.Combine(fixture, "private.txt"), "DO_NOT_SERVE", Encoding.ASCII);
                Check(!new GamePaths(fixture).HasWeb && !new GamePaths(fixture).HasWindows, "Incomplete exports are reported missing", report);
                File.WriteAllText(Path.Combine(web, "index.js"), "JS_FIXTURE", Encoding.ASCII);
                File.WriteAllText(Path.Combine(web, "index.pck"), "PCK_FIXTURE", Encoding.ASCII);
                Check(new GamePaths(fixture).HasWeb, "Exports in a path containing spaces are found", report);
                int port;
                using (LocalWebServer server = new LocalWebServer(web, 0))
                {
                    port = server.Port;
                    string response = Request(port, "GET", "/?cache=1", null);
                    Check(response.StartsWith("HTTP/1.1 200") && response.EndsWith("OUTPOST_WEB_FIXTURE"), "GET serves the Web root with query parameters", report);
                    Check(response.Contains("Cross-Origin-Embedder-Policy: require-corp"), "Browser isolation headers are sent", report);
                    Check(Request(port, "GET", "/index.wasm", null).Contains("Content-Type: application/wasm"), "WASM has the required MIME type", report);
                    Check(Request(port, "GET", "/space%20folder/file.txt", null).EndsWith("WITH_SPACES"), "Encoded spaces are served", report);
                    Check(Request(port, "HEAD", "/", null).EndsWith("\r\n\r\n"), "HEAD returns headers without the file body", report);
                    Check(Request(port, "GET", "/missing", null).StartsWith("HTTP/1.1 404"), "Missing file returns 404", report);
                    foreach (string path in new string[] { "/../private.txt", "/%2e%2e/private.txt", "/%2e%2e%5cprivate.txt", "/C:/Windows/win.ini" })
                        Check(Request(port, "GET", path, null).StartsWith("HTTP/1.1 403"), "Path escape rejected: " + path, report);
                    Check(Request(port, "POST", "/", null).StartsWith("HTTP/1.1 405"), "Write methods are rejected", report);
                    Check(Request(port, "GET", "/", "example.invalid").StartsWith("HTTP/1.1 403"), "Unexpected Host is rejected", report);
                }
                bool closed = false;
                try { using (TcpClient client = new TcpClient()) { client.Connect(IPAddress.Loopback, port); } }
                catch (SocketException) { closed = true; }
                Check(closed, "Closing the server releases its port", report);
                using (LocalWebServer reopened = new LocalWebServer(web, port))
                    Check(reopened.Url == "http://127.0.0.1:" + port + "/", "A fixed port preserves the browser origin between launches", report);
                report.AppendLine("PASS: launcher contract checks completed.");
                result = 0;
            }
            catch (Exception error) { report.AppendLine("FAIL: " + error.ToString()); }
            finally
            {
                if (Directory.Exists(fixture)) Directory.Delete(fixture, true);
                File.WriteAllText(reportPath, report.ToString(), Encoding.UTF8);
            }
            return result;
        }
        private static void Check(bool condition, string name, StringBuilder report)
        {
            if (!condition) throw new InvalidOperationException(name);
            report.AppendLine("PASS: " + name);
        }
        private static string Request(int port, string method, string target, string host)
        {
            using (TcpClient client = new TcpClient())
            {
                client.ReceiveTimeout = 5000;
                client.Connect(IPAddress.Loopback, port);
                using (NetworkStream stream = client.GetStream())
                {
                    byte[] request = Encoding.ASCII.GetBytes(method + " " + target + " HTTP/1.1\r\nHost: " + (host ?? "127.0.0.1:" + port) + "\r\nConnection: close\r\n\r\n");
                    stream.Write(request, 0, request.Length);
                    using (StreamReader reader = new StreamReader(stream)) return reader.ReadToEnd();
                }
            }
        }
    }
}
