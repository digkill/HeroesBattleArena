extends Node3D
class_name GameManager

@export var rakshasa_scene: PackedScene
@export var butcher_scene: PackedScene

@onready var sunrise_spawn_hero: Node3D = $SunriseSpawnHero
@onready var sunset_spawn_hero: Node3D = $SunsetSpawnHero
@onready var camera_rig: CameraController = $CameraRig
@onready var game_ui: GameUI = $GameUI

func _ready() -> void:
	InputSetup.ensure_actions()
	spawn_player_hero()

func spawn_player_hero() -> void:
	var hero_scene := rakshasa_scene
	var selected_hero := get_selected_hero()
	if selected_hero == "butcher" and butcher_scene != null:
		hero_scene = butcher_scene
	if hero_scene == null:
		return

	var hero := hero_scene.instantiate()
	var side := get_selected_side()
	var spawn_pos := Vector3.ZERO
	hero.team = 1
	if side == "Sunset" and sunset_spawn_hero != null:
		spawn_pos = sunset_spawn_hero.position
		hero.team = 2
	elif sunrise_spawn_hero != null:
		spawn_pos = sunrise_spawn_hero.position
	hero.position = spawn_pos
	add_child(hero)

	if camera_rig != null:
		camera_rig.global_position = hero.global_position
		camera_rig.set_target(hero)
	if game_ui != null:
		game_ui.set_hero(hero)

func get_selected_side() -> String:
	if get_tree().has_meta("selected_side"):
		return str(get_tree().get_meta("selected_side"))
	return "Sunrise"

func get_selected_hero() -> String:
	if get_tree().has_meta("selected_hero"):
		return str(get_tree().get_meta("selected_hero"))
	return "rakshasa"
