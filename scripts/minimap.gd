extends Control
class_name Minimap

@export var world_min: Vector3 = Vector3(-90, 0, -90)
@export var world_max: Vector3 = Vector3(90, 0, 90)
@export var camera_rig_path: NodePath
@export var minimap_size: Vector2i = Vector2i(240, 240)
@export var icon_size: float = 4.0
@export var hero_icon_size: float = 6.0
@export var update_interval: float = 0.15
@export var camera_rect_color: Color = Color(1, 1, 0.2, 0.12)
@export var camera_rect_border: Color = Color(1, 1, 0.2, 0.8)
@export var camera_rect_border_width: float = 1.0
@export var ortho_height: float = 220.0
@export var invert_x := false
@export var invert_y := false

@onready var viewport: SubViewport = $SubViewport
@onready var minimap_texture: TextureRect = $Frame/TextureRect
@onready var overlay: Control = $Frame/Overlay
@onready var camera_rect: Panel = $Frame/CameraRect
@onready var minimap_camera: Camera3D = $SubViewport/MinimapCamera
@onready var frame: Control = $Frame

var player_hero: Hero
var icon_nodes: Dictionary = {}
var update_timer: float = 0.0
var dragging: bool = false

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    minimap_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
    overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    camera_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    frame.mouse_filter = Control.MOUSE_FILTER_IGNORE

    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    viewport.size = minimap_size
    viewport.world_3d = get_viewport().world_3d

    minimap_texture.texture = viewport.get_texture()
    minimap_texture.stretch_mode = TextureRect.STRETCH_SCALE

    custom_minimum_size = Vector2(minimap_size.x, minimap_size.y)
    setup_minimap_camera()
    setup_camera_rect_style()

func set_player_hero(hero: Hero) -> void:
    player_hero = hero

func _process(delta: float) -> void:
    update_timer -= delta
    if update_timer <= 0.0:
        update_timer = update_interval
        refresh_icons()

    update_icon_positions()
    update_camera_rect()

func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        var mouse_event: InputEventMouseButton = event
        var local_pos: Vector2 = mouse_event.position
        if mouse_event.button_index == MOUSE_BUTTON_LEFT:
            dragging = mouse_event.pressed
            if dragging:
                move_camera_to(minimap_to_world(local_pos))
        elif mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed:
            issue_move_command(minimap_to_world(local_pos))
    elif event is InputEventMouseMotion and dragging:
        var motion_event: InputEventMouseMotion = event
        var local_pos: Vector2 = motion_event.position
        move_camera_to(minimap_to_world(local_pos))

func setup_minimap_camera() -> void:
    if minimap_camera == null:
        return
    minimap_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    var center: Vector3 = (world_min + world_max) * 0.5
    var width: float = abs(world_max.x - world_min.x)
    var depth: float = abs(world_max.z - world_min.z)
    var ortho_size: float = max(width, depth)
    minimap_camera.size = ortho_size
    minimap_camera.near = 0.1
    minimap_camera.far = ortho_height * 2.0 + 100.0
    minimap_camera.global_position = Vector3(center.x, ortho_height, center.z)
    minimap_camera.rotation_degrees = Vector3(-90, 0, 0)

func setup_camera_rect_style() -> void:
    var style := StyleBoxFlat.new()
    style.bg_color = camera_rect_color
    style.border_width_left = int(camera_rect_border_width)
    style.border_width_right = int(camera_rect_border_width)
    style.border_width_top = int(camera_rect_border_width)
    style.border_width_bottom = int(camera_rect_border_width)
    style.border_color = camera_rect_border
    camera_rect.add_theme_stylebox_override("panel", style)

func refresh_icons() -> void:
    var units: Array[Node] = get_tree().get_nodes_in_group("unit")
    var seen: Dictionary = {}
    for node in units:
        var unit: Unit = node as Unit
        if unit == null:
            continue
        if unit.is_dead:
            continue
        seen[unit] = true
        var icon: ColorRect = icon_nodes.get(unit, null) as ColorRect
        if icon == null:
            icon = create_icon_for_unit(unit)
            overlay.add_child(icon)
            icon_nodes[unit] = icon

    for key in icon_nodes.keys():
        if not is_instance_valid(key) or not seen.has(key):
            var icon_node: ColorRect = icon_nodes[key] as ColorRect
            if icon_node != null:
                icon_node.queue_free()
            icon_nodes.erase(key)

func create_icon_for_unit(unit: Unit) -> ColorRect:
    var icon := ColorRect.new()
    var size: float = hero_icon_size if unit is Hero else icon_size
    icon.size = Vector2(size, size)
    icon.color = get_unit_color(unit)
    icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return icon

func get_unit_color(unit: Unit) -> Color:
    if unit is Hero:
        if player_hero != null and unit == player_hero:
            return Color(0.3, 0.8, 1.0, 1.0)
        return Color(0.2, 0.6, 1.0, 1.0)
    if unit is Summon:
        return Color(0.2, 0.9, 0.5, 1.0)
    if unit.team == 1:
        return Color(0.35, 0.75, 1.0, 1.0)
    return Color(0.95, 0.2, 0.2, 1.0)

func update_icon_positions() -> void:
    var size: Vector2 = minimap_texture.size
    if size.x <= 0.0 or size.y <= 0.0:
        return
    for key in icon_nodes.keys():
        var unit: Unit = key as Unit
        var icon: ColorRect = icon_nodes[key] as ColorRect
        if unit == null or icon == null:
            continue
        var pos: Vector2 = world_to_minimap(unit.global_position)
        icon.position = pos - icon.size * 0.5

func update_camera_rect() -> void:
    var cam: Camera3D = get_viewport().get_camera_3d()
    if cam == null:
        return
    var corners := [
        Vector2(0, 0),
        Vector2(get_viewport().size.x, 0),
        Vector2(get_viewport().size.x, get_viewport().size.y),
        Vector2(0, get_viewport().size.y)
    ]
    var points: Array[Vector3] = []
    for corner in corners:
        var world_point: Vector3 = project_to_ground(cam, corner)
        if world_point != Vector3.INF:
            points.append(world_point)
    if points.size() == 0:
        return
    var min_x: float = points[0].x
    var max_x: float = points[0].x
    var min_z: float = points[0].z
    var max_z: float = points[0].z
    for point in points:
        min_x = min(min_x, point.x)
        max_x = max(max_x, point.x)
        min_z = min(min_z, point.z)
        max_z = max(max_z, point.z)
    var top_left: Vector2 = world_to_minimap(Vector3(min_x, 0.0, max_z))
    var bottom_right: Vector2 = world_to_minimap(Vector3(max_x, 0.0, min_z))
    var rect_pos: Vector2 = Vector2(min(top_left.x, bottom_right.x), min(top_left.y, bottom_right.y))
    var rect_size: Vector2 = Vector2(abs(bottom_right.x - top_left.x), abs(bottom_right.y - top_left.y))
    camera_rect.position = rect_pos
    camera_rect.size = rect_size

func project_to_ground(cam: Camera3D, screen_pos: Vector2) -> Vector3:
    var origin: Vector3 = cam.project_ray_origin(screen_pos)
    var dir: Vector3 = cam.project_ray_normal(screen_pos)
    if abs(dir.y) < 0.0001:
        return Vector3.INF
    var t: float = -origin.y / dir.y
    if t < 0.0:
        return Vector3.INF
    return origin + dir * t

func world_to_minimap(world_pos: Vector3) -> Vector2:
    var size: Vector2 = minimap_texture.size
    var width: float = world_max.x - world_min.x
    var depth: float = world_max.z - world_min.z
    if abs(width) <= 0.0001 or abs(depth) <= 0.0001:
        return Vector2.ZERO
    var norm_x: float = (world_pos.x - world_min.x) / width
    var norm_y: float = (world_pos.z - world_min.z) / depth
    var x: float = (1.0 - norm_x) * size.x if invert_x else norm_x * size.x
    var y: float = (1.0 - norm_y) * size.y if invert_y else norm_y * size.y
    return Vector2(x, y)

func minimap_to_world(minimap_pos: Vector2) -> Vector3:
    var size: Vector2 = minimap_texture.size
    if size.x <= 0.0 or size.y <= 0.0:
        return Vector3.ZERO
    var norm_x: float = clamp(minimap_pos.x / size.x, 0.0, 1.0)
    var norm_y: float = clamp(minimap_pos.y / size.y, 0.0, 1.0)
    if invert_x:
        norm_x = 1.0 - norm_x
    if invert_y:
        norm_y = 1.0 - norm_y
    var world_x: float = lerp(world_min.x, world_max.x, norm_x)
    var world_z: float = lerp(world_min.z, world_max.z, norm_y)
    return Vector3(world_x, 0.0, world_z)

func move_camera_to(world_pos: Vector3) -> void:
    if camera_rig_path == NodePath():
        return
    var rig: Node3D = get_node_or_null(camera_rig_path) as Node3D
    if rig == null:
        return
    var pos: Vector3 = rig.global_position
    pos.x = world_pos.x
    pos.z = world_pos.z
    rig.global_position = pos

func issue_move_command(world_pos: Vector3) -> void:
    if player_hero == null or not is_instance_valid(player_hero):
        return
    player_hero.issue_move_to_world(world_pos)
