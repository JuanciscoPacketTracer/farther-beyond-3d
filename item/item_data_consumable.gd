extends ItemData
class_name ItemDataConsumable
@export var heal_value: int
enum HealType { NORMAL, MAX_UP }
@export var heal_type: HealType = HealType.NORMAL

func use(target) -> void:
	match heal_type:
		HealType.NORMAL:
			target.heal(heal_value)
		HealType.MAX_UP:
			target.max_health += heal_value
			target.health = target.max_health
			target.healparticles.emitting = true
			if target.hearts_hud:
				target.hearts_hud.update_health(target.health, target.max_health)
