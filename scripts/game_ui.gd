extends CanvasLayer
class_name GameUI

@onready var health_bar: ProgressBar = $HUD/HealthBar
@onready var mana_bar: ProgressBar = $HUD/ManaBar
@onready var xp_bar: ProgressBar = $HUD/XPBar
@onready var gold_label: Label = $HUD/GoldLabel
@onready var level_label: Label = $HUD/LevelLabel
@onready var stat_label: Label = $HUD/StatLabel
@onready var ability_buttons := [
    $HUD/Abilities/Ability1,
    $HUD/Abilities/Ability2,
    $HUD/Abilities/Ability3,
    $HUD/Abilities/Ability4
]
@onready var ability_cooldowns := [
    $HUD/Abilities/Ability1/Cooldown,
    $HUD/Abilities/Ability2/Cooldown,
    $HUD/Abilities/Ability3/Cooldown,
    $HUD/Abilities/Ability4/Cooldown
]
@onready var item_buttons := [
    $HUD/Items/Item1,
    $HUD/Items/Item2,
    $HUD/Items/Item3
]
@onready var attack_button: Button = $HUD/Commands/AttackButton
@onready var stop_button: Button = $HUD/Commands/StopButton
@onready var shop_panel: Panel = $ShopPanel
@onready var shop_list: VBoxContainer = $ShopPanel/Scroll/ShopList
@onready var minimap: Minimap = $Minimap

var hero: Hero

func _ready() -> void:
    InputSetup.ensure_actions()
    shop_panel.visible = false
    set_process_unhandled_input(true)

    for i in range(ability_buttons.size()):
        ability_buttons[i].pressed.connect(_on_ability_pressed.bind(i))

    for i in range(item_buttons.size()):
        item_buttons[i].pressed.connect(_on_item_pressed.bind(i))

    if attack_button != null:
        attack_button.pressed.connect(_on_attack_pressed)
    if stop_button != null:
        stop_button.pressed.connect(_on_stop_pressed)

    build_shop()

func _unhandled_input(event: InputEvent) -> void:
    if Input.is_action_just_pressed("toggle_shop"):
        shop_panel.visible = not shop_panel.visible

func set_hero(new_hero: Hero) -> void:
    hero = new_hero
    if hero == null:
        return
    hero.gold_changed.connect(_on_gold_changed)
    hero.level_changed.connect(_on_level_changed)
    hero.xp_changed.connect(_on_xp_changed)
    _on_gold_changed(hero.gold)
    _on_level_changed(hero.level)
    _on_xp_changed(hero.xp, hero.xp_to_next)
    update_stat_label()
    update_ability_labels()
    if minimap != null:
        minimap.set_player_hero(hero)

func _process(delta: float) -> void:
    if hero == null:
        return

    health_bar.max_value = hero.max_health
    health_bar.value = hero.health
    mana_bar.max_value = hero.max_mana
    mana_bar.value = hero.mana

    update_stat_label()
    update_abilities()
    update_items()

func update_stat_label() -> void:
    if hero == null:
        return
    var main_label: String = hero.get_main_attribute_label()
    stat_label.text = "STR %d  AGI %d  INT %d  | Main: %s" % [int(hero.strength), int(hero.agility), int(hero.intelligence), main_label]

func update_ability_labels() -> void:
    if hero == null:
        return
    for i in range(ability_buttons.size()):
        var name: String = hero.get_ability_name(i)
        var hotkey: String = hero.get_ability_hotkey(i)
        if name == "":
            ability_buttons[i].text = "-"
            ability_buttons[i].disabled = true
            ability_cooldowns[i].text = ""
        else:
            ability_buttons[i].text = "%s %s" % [hotkey, name] if hotkey != "" else name

func update_abilities() -> void:
    for i in range(ability_buttons.size()):
        var name: String = hero.get_ability_name(i)
        if name == "":
            ability_buttons[i].disabled = true
            ability_cooldowns[i].text = ""
            continue
        var cd: float = hero.get_ability_cooldown(i)
        var mana_cost: float = hero.get_ability_mana(i)
        ability_buttons[i].disabled = cd > 0.0 or hero.mana < mana_cost
        if cd > 0.0:
            ability_cooldowns[i].text = str(int(ceil(cd)))
        else:
            ability_cooldowns[i].text = ""

func update_items() -> void:
    for i in range(item_buttons.size()):
        var item_id := hero.inventory.get_item(i)
        if item_id == "":
            item_buttons[i].text = "-"
            item_buttons[i].disabled = true
        else:
            var item := ItemDb.get_item(item_id)
            item_buttons[i].text = item.get("name", item_id)
            item_buttons[i].disabled = false

func build_shop() -> void:
    for item_id in ItemDb.get_shop_items():
        var item := ItemDb.get_item(item_id)
        var button := Button.new()
        button.text = "%s (%d)" % [item.get("name", item_id), int(item.get("cost", 0))]
        button.pressed.connect(_on_buy_item.bind(item_id))
        shop_list.add_child(button)

func _on_buy_item(item_id: String) -> void:
    if hero == null:
        return
    hero.buy_item(item_id)

func _on_ability_pressed(index: int) -> void:
    if hero == null:
        return
    hero.cast_ability(index)

func _on_item_pressed(index: int) -> void:
    if hero == null:
        return
    hero.use_item(index)

func _on_attack_pressed() -> void:
    if hero == null:
        return
    hero.queue_attack_command()

func _on_stop_pressed() -> void:
    if hero == null:
        return
    hero.stop_actions()

func _on_gold_changed(value: int) -> void:
    gold_label.text = "Gold: %d" % value

func _on_level_changed(value: int) -> void:
    level_label.text = "Level: %d" % value

func _on_xp_changed(value: int, total: int) -> void:
    xp_bar.max_value = total
    xp_bar.value = value
