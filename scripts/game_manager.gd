extends Node3D
class_name GameManager

@export var rakshasa_scene: PackedScene

@onready var hero_spawn_sunrise: Node3D = $HeroSpawnSunrise
@onready var hero_spawn_sunset: Node3D = $HeroSpawnSunset
@onready var camera_rig: CameraController = $CameraRig
@onready var game_ui: GameUI = $GameUI

func _ready() -> void:
    InputSetup.ensure_actions()
    spawn_player_hero()

func spawn_player_hero() -> void:
    var hero_scene := rakshasa_scene
    if hero_scene == null:
        return

    var hero := hero_scene.instantiate()
    var side := get_selected_side()
    if side == "Sunset" and hero_spawn_sunset != null:
        hero.global_position = hero_spawn_sunset.global_position
        hero.team = 2
    elif hero_spawn_sunrise != null:
        hero.global_position = hero_spawn_sunrise.global_position
        hero.team = 1
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
