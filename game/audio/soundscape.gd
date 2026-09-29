extends Node

var wind: AudioStreamPlayer
var engine: AudioStreamPlayer3D
var feedback: AudioStreamPlayer
var active := false
var volume := 0.45


func _ready() -> void:
	wind = AudioStreamPlayer.new()
	wind.stream = _sound("wind", 3.0, true)
	wind.volume_db = -28
	add_child(wind)
	engine = AudioStreamPlayer3D.new()
	engine.position = Vector3(-10, 1, -4)
	engine.stream = _sound("engine", 1.0, true)
	engine.unit_size = 9
	engine.max_distance = 30
	engine.volume_db = -18
	add_child(engine)
	feedback = AudioStreamPlayer.new()
	feedback.volume_db = -13
	add_child(feedback)


func set_active(enabled: bool) -> void:
	active = enabled
	if enabled and not wind.playing:
		wind.play()
	elif not enabled:
		wind.stop()
		engine.stop()


func sync(generator_on: bool, master_volume: float) -> void:
	volume = master_volume
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(0.001, volume)))
	if active and generator_on and not engine.playing:
		engine.play()
	elif not generator_on or not active:
		engine.stop()


func play_feedback(kind := "pickup") -> void:
	if not active:
		return
	feedback.stream = _sound(kind, 0.22, false)
	feedback.play()


func _sound(kind: String, seconds: float, loop: bool) -> AudioStreamWAV:
	const RATE := 16000
	var count := int(RATE * seconds)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4917
	var filtered := 0.0
	for i in range(count):
		var t := float(i) / RATE
		var value := 0.0
		match kind:
			"wind":
				filtered = lerpf(filtered, rng.randf_range(-1, 1), 0.025)
				value = filtered * 0.7 * (0.65 + 0.35 * sin(TAU * t / seconds))
			"engine":
				value = sin(TAU * 64 * t) * 0.17 + sin(TAU * 128 * t) * 0.07 + rng.randf_range(-0.03, 0.03)
			_:
				var frequency := 620.0 if kind == "pickup" else 420.0
				value = sin(TAU * (frequency + t * 700) * t) * 0.3 * pow(1 - t / seconds, 2)
		var sample := clampi(int(value * 32767), -32768, 32767)
		bytes.encode_s16(i * 2, sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.data = bytes
	if loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = count
	return stream
