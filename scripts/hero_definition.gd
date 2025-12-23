extends Resource
class_name HeroDefinition

@export var hero_id: StringName = &""
@export var display_name: String = ""
@export var main_attribute: StringName = &"agility"
@export var model_scene: PackedScene
@export var model_node_path: NodePath = NodePath()
@export var model_offset: Vector3 = Vector3.ZERO
@export var model_rotation_degrees: Vector3 = Vector3.ZERO
@export var model_scale: Vector3 = Vector3.ONE

@export var base_strength: float = 18.0
@export var base_agility: float = 22.0
@export var base_intelligence: float = 16.0
@export var strength_gain: float = 2.1
@export var agility_gain: float = 2.8
@export var intelligence_gain: float = 1.7
@export var base_attack_damage: float = 22.0
@export var base_attack_cooldown: float = 1.6
@export var base_move_speed: float = 6.0

@export var abilities: Array[AbilityDefinition] = []

@export var anim_idle: StringName = &""
@export var anim_move: StringName = &""
@export var anim_attack: StringName = &""
@export var anim_cast: StringName = &""
@export var anim_death: StringName = &""
@export var anim_hit: StringName = &""
@export var anim_jump: StringName = &""
@export var anim_skill1: StringName = &""
@export var anim_skill2: StringName = &""
@export var anim_skill3: StringName = &""
@export var anim_skill4: StringName = &""
@export var anim_ultimate: StringName = &""
@export var anim_teleportation: StringName = &""
@export var anim_stun: StringName = &""
@export var anim_won: StringName = &""
@export var anim_fall: StringName = &""
@export var anim_loss: StringName = &""
@export var anim_use_item: StringName = &""
