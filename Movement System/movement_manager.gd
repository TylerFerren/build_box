class_name MovementManager
extends Node

@export var controller : CharacterBody3D
@export var camera : Camera3D

var extensions : Array[MovementExtension] = []
var additive_extensions: Array[MovementExtension] = []
var subtractive_extensions: Array[MovementExtension] = []
var overriding_extensions: Array[MovementExtension] = []
var constant_extensions: Array[MovementExtension] = []

var is_grounded : bool

func _ready() -> void:
	extensions.clear()
	additive_extensions.clear()
	subtractive_extensions.clear()
	overriding_extensions.clear()
	constant_extensions.clear()

	for child in get_children():
		if child is MovementExtension:
			extensions.append(child)
	
	for extension in extensions:
		extension.manager = self
		match extension.blend_mode:
			MovementExtension.ExtensionBlendMode.ADDITIVE:
				additive_extensions.append(extension)
			MovementExtension.ExtensionBlendMode.SUBTRACTIVE:
				subtractive_extensions.append(extension)
			MovementExtension.ExtensionBlendMode.OVERRIDING:
				overriding_extensions.append(extension)
			MovementExtension.ExtensionBlendMode.CONSTANT:
				constant_extensions.append(extension)

func _physics_process(delta: float) -> void:
	ground_check()
	
	controller.velocity = get_movement_vector(delta)
	controller.move_and_slide()
	
	get_rotation_vector(delta)
	controller.rotation = rotation_vector
	

func ground_check():
	is_grounded = controller.is_on_floor()

var movement_vector : Vector3
func get_movement_vector(delta: float = 0.0) -> Vector3:
	var _move_vector = Vector3.ZERO
	var _constant_move_vector = Vector3.ZERO
	
	var _constant_extensions = get_extension_by_blend_mode(MovementExtension.ExtensionBlendMode.CONSTANT)
	for _extension in _constant_extensions:
		if _extension.is_active:
			_constant_move_vector = _extension.get_movement_vector(delta)
	
	var _overriding_extensions = get_extension_by_blend_mode(MovementExtension.ExtensionBlendMode.OVERRIDING)
	for _extension in _overriding_extensions:
		if _extension.is_active:
			_move_vector =  _extension.get_movement_vector(delta)
			movement_vector = _constant_move_vector + _move_vector
			return movement_vector
	
	var _additive_extensions = get_extension_by_blend_mode(MovementExtension.ExtensionBlendMode.ADDITIVE)
	for _extension in _additive_extensions:
		if _extension.is_active:
			_move_vector += _extension.get_movement_vector(delta)
	
	var _subtractive_extensions = get_extension_by_blend_mode(MovementExtension.ExtensionBlendMode.SUBTRACTIVE)
	for _extension in _subtractive_extensions:
		if _extension.is_active:
			_move_vector -= _extension.get_movement_vector(delta)
	
	movement_vector = _constant_move_vector + _move_vector
	return movement_vector

var rotation_vector : Vector3
func get_rotation_vector(delta: float = 0.0) -> Vector3:
	var _rotation_vector = Vector3.ZERO
	var _constant_rotation_vector = Vector3.ZERO
	
	var _constant_extensions = get_extension_by_blend_mode(MovementExtension.ExtensionBlendMode.CONSTANT)
	for _extension in _constant_extensions:
		if _extension.is_active:
			_constant_rotation_vector = _extension.get_rotation_vector(delta)
	
	var _overriding_extensions = get_extension_by_blend_mode(MovementExtension.ExtensionBlendMode.OVERRIDING)
	for _extension in _overriding_extensions:
		if _extension.is_active:
			_rotation_vector =  _extension.get_rotation_vector(delta)
			rotation_vector = _constant_rotation_vector + _rotation_vector
			return rotation_vector
	
	var _additive_extensions = get_extension_by_blend_mode(MovementExtension.ExtensionBlendMode.ADDITIVE)
	for _extension in _additive_extensions:
		if _extension.is_active:
			_rotation_vector += _extension.get_rotation_vector(delta)
	
	var _subtractive_extensions = get_extension_by_blend_mode(MovementExtension.ExtensionBlendMode.SUBTRACTIVE)
	for _extension in _subtractive_extensions:
		if _extension.is_active:
			_rotation_vector -= _extension.get_rotation_vector(delta)
	
	rotation_vector = _constant_rotation_vector + _rotation_vector
	return rotation_vector

func get_extension_by_blend_mode(blend_mode : MovementExtension.ExtensionBlendMode) -> Array[MovementExtension]:
	match blend_mode:
		MovementExtension.ExtensionBlendMode.ADDITIVE:
			return additive_extensions
		MovementExtension.ExtensionBlendMode.SUBTRACTIVE:
			return subtractive_extensions
		MovementExtension.ExtensionBlendMode.OVERRIDING:
			return overriding_extensions
		MovementExtension.ExtensionBlendMode.CONSTANT:
			return constant_extensions
	return []
	

func get_camera_relative_input (_input : Vector3) -> Vector3:
	if camera:
		var _relative_input = Quaternion.from_euler(camera.rotation) * _input
		return _relative_input
	else:
		return _input
	

#-------------------------------------------------------------
		#public Vector2 MoveInputVector { get; private set; }
#
		#private float originalCharacterHeight;
		#// public UnityEvent<bool> OnGroundCheck;
#
		#void Awake()
		#{
			#Cam = Cam != null ? Cam : Camera.main;
			#originalCharacterHeight = controller.height;
		#}
#
		#void Update()
		#{
			#Vector3 combinedRotation = GetRotationVector();
#
			#if (combinedRotation != Vector3.zero)
			#{
				#controller.transform.rotation = Quaternion.RotateTowards(
					#controller.transform.rotation,
					#Quaternion.Euler(combinedRotation),
					#Time.deltaTime * 360f
				#);
			#}
		#}
		#public void GroundCheck()
		#{
			#var hitColliders = Physics.OverlapSphere(controller.transform.position, controller.radius * 0.95f);
			#IsGrounded = false;
			#
			#foreach (Collider collider in hitColliders)
			#{
				#if (collider == controller)
					#continue;
				#IsGrounded = true;
			#}
			#// IsGrounded = characterController.isGrounded;
			#// OnGroundCheck.Invoke(IsGrounded);
		#}

		#//returns a Vector Relative to the characters rotation
		#public Vector3 GetCharacterRelativeInput()
		#{
			#Vector3 relativeInput = Quaternion.Euler(0, controller.transform.eulerAngles.y, 0) * new Vector3(MoveInputVector.x, 0, MoveInputVector.y);
			#return relativeInput;
		#}
#
		#public Vector3 GetCharacterRelativeInput(Vector2 moveInputVector)
		#{
			#Vector3 relativeInput = Quaternion.Euler(0, controller.transform.eulerAngles.y, 0) * new Vector3(moveInputVector.x, 0, moveInputVector.y);
			#return relativeInput;
		#}
#
		#public Vector3 GetCharacterRelativeInput(Vector3 moveInputVector)
		#{
			#Vector3 relativeInput = Quaternion.Euler(0, controller.transform.eulerAngles.y, 0) * moveInputVector;
			#return relativeInput;
		#}
#
		#//returns a Vector Relative to the character up Vector
		#public Vector3 ProjectOnCharacterPlane(Vector3 direction)
		#{
			#return Vector3.ProjectOnPlane(direction, controller.transform.up);
		#}
		
		#public IEnumerator LerpControllerHeight(float newHeight = 2, float time = 0.3f)
		#{
			#var heightDelta = Mathf.Abs(newHeight - Controller.height) / time;
#
			#var timeCount = 0f;
			#while (Controller.height != newHeight || timeCount > time)
			#{
				#Controller.height = Mathf.MoveTowards(Controller.height, newHeight, heightDelta * Time.deltaTime);
				#Controller.center = new Vector3(Controller.center.x, Controller.height / 2, Controller.center.z);
				#
				#time += Time.deltaTime;
				#yield return null;
			#}
#
			#controller.height = newHeight;
		#}
#
		#public void ResetControllerHeight(float time = 0.3f)
		#{
			#StartCoroutine(LerpControllerHeight(originalCharacterHeight, time));
		#}
