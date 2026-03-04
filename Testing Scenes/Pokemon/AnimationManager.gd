extends AnimationTree


@export var movement_manager : MovementManager
@export var movement_mode_manager : MovementModeManager

func _process(_delta: float) -> void:
	self["parameters/Grounded/Locomotion/blend_position"] = Vector3(movement_manager.controller.velocity.x, 0, movement_manager.controller.velocity.z).length()
	self["parameters/Flight/flight locomotion/blend_position"] = Vector3(movement_manager.controller.velocity.x, 0, movement_manager.controller.velocity.z).length()
	if movement_manager.controller.velocity.y < 0:
		self["parameters/Grounded/conditions/is_falling"] = true
	else:
		self["parameters/Grounded/conditions/is_falling"] = false
	
	self["parameters/Grounded/conditions/is_grounded"] = movement_manager.controller.is_on_floor()
	
	if movement_mode_manager.current_mode == "flying":
		self["parameters/Blend2/blend_amount"] = 1
	else:
		self["parameters/Blend2/blend_amount"] = 0
	

func _is_jumping() -> void:
	self["parameters/Grounded/conditions/is_jumping"] = true
	await get_tree().create_timer(0.1).timeout
	self["parameters/Grounded/conditions/is_jumping"] = false
