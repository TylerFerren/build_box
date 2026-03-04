class_name MovementStateSettingOverride
extends Resource

enum SettingKey {
	SPEED_MULTIPLIER,
	GRAVITY_SCALE
}

@export var setting_key: SettingKey = SettingKey.SPEED_MULTIPLIER
@export var value: float = 1.0
