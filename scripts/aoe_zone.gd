extends Area3D
class_name AoEZone

@export var duration := 3.5
@export var tick_interval := 0.5
@export var damage_per_tick := 12.0
@export var slow_multiplier := 0.7
@export var slow_duration := 1.0

var team := 1
var tick_timer := 0.0
var source_unit: Unit

func _ready() -> void:
    tick_timer = tick_interval

func _physics_process(delta: float) -> void:
    duration -= delta
    if duration <= 0.0:
        queue_free()
        return

    tick_timer -= delta
    if tick_timer <= 0.0:
        tick_timer = tick_interval
        apply_tick()

func apply_tick() -> void:
    var bodies := get_overlapping_bodies()
    for body in bodies:
        if body is Unit and body.team != team:
            var source: Node = source_unit if source_unit != null else self
            body.take_damage(damage_per_tick, source)
            body.apply_slow(slow_multiplier, slow_duration)
