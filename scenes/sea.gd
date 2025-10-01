extends MeshInstance3D

@export var player: CharacterBody3D
func _ready() -> void:
	self.position.y = 0

func _physics_process(delta: float) -> void:
	self.position.x = player.position.x
	self.position.z = player.position.z
