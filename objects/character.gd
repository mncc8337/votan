extends CharacterBody3D

@export var speed = 10.0
@export var jump_impulse = 20.0
@export var gravity = -20.5

@export var camera_sensitivity: float = 0.005

func _unhandled_input(event):
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and event is InputEventMouseMotion:
		var deltay = -event.relative.x * camera_sensitivity
		%CameraPivot.rotation.y += deltay
		%CameraPlaneDirection.rotation.y = %CameraPivot.rotation.y
		%CameraPivot.rotation.x += -event.relative.y * camera_sensitivity
		%CameraPivot.rotation.x = clamp(%CameraPivot.rotation.x, -PI/2, PI/2)

func _input(event):
	if event.is_action_pressed("left_click"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta):
	velocity.x *= 0.3
	velocity.z *= 0.3

	if not is_on_floor():
		velocity.y += gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y += jump_impulse

	var dir_z = Input.get_axis("backward", "forward")
	var dir_x = Input.get_axis("right", "left")
	velocity += -%CameraPlaneDirection.global_basis.z * dir_z * speed
	velocity += -%CameraPlaneDirection.global_basis.x * dir_x * speed
	
	if velocity != Vector3.ZERO:
		%Mesh.rotation.y = lerp(%Mesh.rotation.y, %CameraPlaneDirection.rotation.y, 0.1)

	move_and_slide()
