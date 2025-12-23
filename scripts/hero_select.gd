extends Control
class_name HeroSelect

@onready var start_button: Button = $Panel/StartButton
@onready var hero_button: Button = $Panel/HeroCard
@onready var selection_label: Label = $Panel/SelectionLabel
@onready var sunrise_button: Button = $Panel/SideButtons/SunriseButton
@onready var sunset_button: Button = $Panel/SideButtons/SunsetButton
@onready var side_label: Label = $Panel/SideLabel

var selected_hero := "Rakshasa"
var selected_side := "Sunrise"

func _ready() -> void:
    InputSetup.ensure_actions()
    hero_button.pressed.connect(_on_hero_pressed)
    sunrise_button.pressed.connect(_on_sunrise_pressed)
    sunset_button.pressed.connect(_on_sunset_pressed)
    start_button.pressed.connect(_on_start_pressed)
    update_selection()

func _on_hero_pressed() -> void:
    selected_hero = "Rakshasa"
    update_selection()

func _on_start_pressed() -> void:
    get_tree().set_meta("selected_hero", selected_hero)
    get_tree().set_meta("selected_side", selected_side)
    get_tree().change_scene_to_file("res://scenes/game.tscn")

func update_selection() -> void:
    selection_label.text = "Selected: %s" % selected_hero
    side_label.text = "Side: %s" % selected_side
    sunrise_button.disabled = selected_side == "Sunrise"
    sunset_button.disabled = selected_side == "Sunset"

func _on_sunrise_pressed() -> void:
    selected_side = "Sunrise"
    update_selection()

func _on_sunset_pressed() -> void:
    selected_side = "Sunset"
    update_selection()
