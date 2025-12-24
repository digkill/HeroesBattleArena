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
	if start_button == null:
		push_error("StartButton not found at $Panel/StartButton.")
	else:
		start_button.pressed.connect(_on_start_pressed)
	update_selection()

func _on_rakshasa_pressed() -> void:
	selected_hero = "rakshasa"
	update_selection()

func _on_butcher_pressed() -> void:
	selected_hero = "butcher"
	update_selection()

func _on_start_pressed() -> void:
	var tree := get_tree()
	if tree == null:
		push_error("SceneTree not available on Start.")
		return
	
	# Отключаем кнопку, чтобы предотвратить повторные нажатия
	start_button.disabled = true
	start_button.text = "Loading..."
	
	# Устанавливаем метаданные
	tree.set_meta("selected_hero", selected_hero)
	tree.set_meta("selected_side", selected_side)
	
	# Загружаем сцену асинхронно
	ResourceLoader.load_threaded_request("res://scenes/game.tscn")
	call_deferred("_check_scene_load")

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

func _check_scene_load() -> void:
	var progress: Array = []
	var status := ResourceLoader.load_threaded_get_status("res://scenes/game.tscn", progress)
	
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		var packed := ResourceLoader.load_threaded_get("res://scenes/game.tscn") as PackedScene
		if packed != null:
			var tree := get_tree()
			if tree != null:
				tree.change_scene_to_packed(packed)
		else:
			push_error("Failed to load res://scenes/game.tscn.")
			start_button.disabled = false
			start_button.text = "Start Match"
	elif status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE or \
		 status == ResourceLoader.THREAD_LOAD_FAILED:
		push_error("Failed to load res://scenes/game.tscn.")
		start_button.disabled = false
		start_button.text = "Start Match"
	else:
		# Все еще загружается, проверяем снова в следующем кадре
		call_deferred("_check_scene_load")
