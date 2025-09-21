extends CharacterBody3D

@export var speed = 10.0
@export var jump_impulse = 20.0
@export var gravity = -20.5

@export var camera_compound: Marker3D
@export var camera_sensitivity: float = 0.005

var is_floating := false
var is_flying := false

var counting_space_press_time := false
var time_between_space_press: float = 0

func _unhandled_input(event):
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and event is InputEventMouseMotion:
		var deltay = -event.relative.x * camera_sensitivity
		camera_compound.rotation.y += deltay
		%PivotPosition.global_rotation.y = camera_compound.global_rotation.y
		camera_compound.rotation.x += -event.relative.y * camera_sensitivity
		camera_compound.rotation.x = clamp(camera_compound.rotation.x, -PI/2, PI/2)

func _input(event):
	if event.is_action_pressed("left_click"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta):
	velocity.x *= 0.2
	velocity.z *= 0.2
	camera_compound.global_position = %PivotPosition.global_position

	if not is_on_floor():
		if not is_floating:
			velocity.y += gravity * delta
		else:
			velocity.y = 0

	if Input.is_action_just_pressed("jump"):
		if not counting_space_press_time:
			counting_space_press_time = true
			time_between_space_press = 0
		else:
			counting_space_press_time = false
			if time_between_space_press < 0.5:
				is_floating = !is_floating
				if is_floating:
					velocity = Vector3.ZERO

		if is_on_floor():
			if is_floating:
				is_floating = false
			else:
				velocity.y += jump_impulse
	elif counting_space_press_time:
		time_between_space_press += delta
	
	if is_floating:
		if Input.is_action_pressed("fly_up"):
			position.y += 10 * delta
		if Input.is_action_pressed("fly_down"):
			position.y -= 10 * delta

	var dir_z = Input.get_axis("backward", "forward")
	var dir_x = Input.get_axis("right", "left")
	velocity += -%PivotPosition.global_basis.z * dir_z * speed
	velocity += -%PivotPosition.global_basis.x * dir_x * speed

	is_flying = is_floating and velocity.length_squared() > 0.3
	
	if velocity.length_squared() > 0.3:
		rotation.y = lerp_angle(rotation.y, camera_compound.rotation.y, 0.5)
	move_and_slide()
