extends CharacterBody3D

const WALK_SPEED := 4.7
const SPRINT_SPEED := 7.5
const JUMP_SPEED := 5.2

var camera: Camera3D
var orbit_yaw := 0.0
var orbit_pitch := 0.45
var camera_distance := 7.0
var rotating := false
var controls_enabled := true
var motion_phase := 0.0
var limbs: Array[Node3D] = []


func _ready() -> void:
	name = "Joueur"
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.38
	capsule.height = 1.75
	collision.shape = capsule
	collision.position.y = 0.9
	add_child(collision)
	var torso := _box(Vector3(0, 1.08, 0), Vector3(0.72, 0.8, 0.4), Color("d99274"))
	torso.name = "Manteau"
	_box(Vector3(0, 1.68, 0), Vector3(0.5, 0.48, 0.5), Color("e2c29d"))
	_box(Vector3(0, 1.94, 0), Vector3(0.6, 0.17, 0.56), Color("253d3f"))
	_box(Vector3(0, 1.03, 0.29), Vector3(0.48, 0.7, 0.25), Color("486965"))
	for x in [-0.2, 0.2]:
		var leg := Node3D.new()
		leg.position = Vector3(x, 0.8, 0)
		add_child(leg)
		var part := _box(Vector3.ZERO, Vector3(0.25, 0.76, 0.28), Color("283f42"))
		part.reparent(leg, false)
		part.position = Vector3(0, -0.38, 0)
		limbs.append(leg)
	for x in [-0.48, 0.48]:
		var arm := Node3D.new()
		arm.position = Vector3(x, 1.4, 0)
		add_child(arm)
		var part := _box(Vector3.ZERO, Vector3(0.2, 0.65, 0.24), Color("d99274"))
		part.reparent(arm, false)
		part.position = Vector3(0, -0.25, 0)
		limbs.append(arm)
	camera = Camera3D.new()
	camera.current = true
	get_parent().add_child(camera)
	_place_camera()


func _physics_process(delta: float) -> void:
	if not controls_enabled:
		return
	var x_axis := 0.0
	var z_axis := 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_Q) or Input.is_key_pressed(KEY_LEFT):
		x_axis -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		x_axis += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_Z) or Input.is_key_pressed(KEY_UP):
		z_axis -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		z_axis += 1.0
	var direction := Basis(Vector3.UP, orbit_yaw) * Vector3(x_axis, 0, z_axis).normalized()
	var speed := SPRINT_SPEED if Input.is_key_pressed(KEY_SHIFT) else WALK_SPEED
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if not is_on_floor():
		velocity.y -= 17.0 * delta
	elif Input.is_key_pressed(KEY_SPACE):
		velocity.y = JUMP_SPEED
	else:
		velocity.y = -0.2
	move_and_slide()
	position.x = clampf(position.x, -40.0, 40.0)
	position.z = clampf(position.z, -40.0, 40.0)
	if position.y < -3.0:
		position = Vector3(-7, 1, 12)
		velocity = Vector3.ZERO
	motion_phase += delta * speed * 2.0
	for i in range(limbs.size()):
		limbs[i].rotation.x = sin(motion_phase + (PI if i % 2 == 0 else 0.0)) * 0.42 * direction.length()
	if direction.length_squared() > 0.01:
		var desired := atan2(-direction.x, -direction.z)
		rotation.y = lerp_angle(rotation.y, desired, minf(1.0, delta * 9.0))
	_place_camera()


func _unhandled_input(event: InputEvent) -> void:
	if not controls_enabled:
		rotating = false
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			rotating = event.pressed
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera_distance = maxf(4.0, camera_distance - 0.7)
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera_distance = minf(11.0, camera_distance + 0.7)
	elif event is InputEventMouseMotion and rotating:
		orbit_yaw -= event.relative.x * 0.006
		orbit_pitch = clampf(orbit_pitch + event.relative.y * 0.004, 0.2, 0.9)
		_place_camera()


func facing_direction() -> Vector3:
	return Basis(Vector3.UP, orbit_yaw) * Vector3.FORWARD


func _place_camera() -> void:
	if camera == null:
		return
	var focus := global_position + Vector3(0, 1.25, 0)
	var offset := Basis(Vector3.UP, orbit_yaw) * Vector3(0, sin(orbit_pitch) * camera_distance, cos(orbit_pitch) * camera_distance)
	camera.global_position = focus + offset
	var ray := PhysicsRayQueryParameters3D.create(focus, camera.global_position)
	ray.exclude = [get_rid()]
	var obstruction := get_world_3d().direct_space_state.intersect_ray(ray)
	if not obstruction.is_empty():
		camera.global_position = obstruction["position"] + obstruction["normal"] * 0.3
	camera.look_at(focus, Vector3.UP)


func set_controls(enabled: bool) -> void:
	controls_enabled = enabled
	rotating = false
	velocity = Vector3.ZERO


func _box(position: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = position
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	instance.material_override = material
	add_child(instance)
	return instance
