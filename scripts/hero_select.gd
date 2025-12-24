extends Control
class_name HeroSelect

@onready var start_button: Button = $Panel/StartButton
@onready var rakshasa_button: Button = $Panel/HeroCards/RakshasaButton
@onready var butcher_button: Button = $Panel/HeroCards/ButcherButton
@onready var selection_label: Label = $Panel/SelectionLabel
@onready var hero_note: Label = $Panel/HeroNote
@onready var sunrise_button: Button = $Panel/SideButtons/SunriseButton
@onready var sunset_button: Button = $Panel/SideButtons/SunsetButton
@onready var side_label: Label = $Panel/SideLabel

var selected_hero: String = "rakshasa"
var selected_side: String = "Sunrise"

func _ready() -> void:
    InputSetup.ensure_actions()
    rakshasa_button.pressed.connect(_on_rakshasa_pressed)
    butcher_button.pressed.connect(_on_butcher_pressed)
    sunrise_button.pressed.connect(_on_sunrise_pressed)
    sunset_button.pressed.connect(_on_sunset_pressed)
    start_button.pressed.connect(_on_start_pressed)
    update_selection()

func _on_rakshasa_pressed() -> void:
    selected_hero = "rakshasa"
    update_selection()

func _on_butcher_pressed() -> void:
    selected_hero = "butcher"
    update_selection()

func _on_start_pressed() -> void:
    get_tree().set_meta("selected_hero", selected_hero)
    get_tree().set_meta("selected_side", selected_side)
    get_tree().change_scene_to_file("res://scenes/game.tscn")

func update_selection() -> void:
    selection_label.text = "Selected: %s" % get_hero_display_name(selected_hero)
    hero_note.text = get_hero_note(selected_hero)
    side_label.text = "Side: %s" % selected_side
    rakshasa_button.disabled = selected_hero == "rakshasa"
    butcher_button.disabled = selected_hero == "butcher"
    sunrise_button.disabled = selected_side == "Sunrise"
    sunset_button.disabled = selected_side == "Sunset"

func get_hero_display_name(hero_id: String) -> String:
    if hero_id == "butcher":
        return "Butcher of the Damned"
    return "Rakshasa"

func get_hero_note(hero_id: String) -> String:
    if hero_id == "butcher":
        return "Main attribute: Strength | Ultimate: Dismember"
    return "Main attribute: Agility | Ultimate: Summon Pack"

func _on_sunrise_pressed() -> void:
    selected_side = "Sunrise"
    update_selection()

func _on_sunset_pressed() -> void:
    selected_side = "Sunset"
    update_selection()
