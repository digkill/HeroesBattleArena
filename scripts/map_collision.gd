extends Node3D
class_name MapCollision

@export var collision_layer := 1
@export var collision_mask := 1
@export var collision_name := "AutoCollision"
@export var build_on_ready := true
@export var skip_decorative_objects := true
@export var min_collision_height := 0.5  # Минимальная высота для создания коллайдера

func _ready() -> void:
    if build_on_ready:
        call_deferred("build_colliders")

func build_colliders() -> void:
    # Откладываем тяжелые операции на следующий кадр, чтобы не блокировать загрузку сцены
    if get_tree() != null:
        await get_tree().process_frame
        await get_tree().process_frame
    
    var meshes: Array[MeshInstance3D] = []
    collect_meshes(self, meshes)
    
    # Обрабатываем меши порциями для оптимизации на Mobile
    var batch_size := 5
    var processed := 0
    for mesh in meshes:
        if mesh.mesh == null:
            continue
        if mesh.get_node_or_null(collision_name) != null:
            continue
        
        # Пропускаем декоративные объекты (трава, кусты)
        if skip_decorative_objects and is_decorative_object(mesh):
            continue
        
        var faces: PackedVector3Array = mesh.mesh.get_faces()
        if faces.is_empty():
            continue
        
        # Проверяем высоту меша - пропускаем маленькие объекты
        if skip_decorative_objects and not is_tall_enough(mesh):
            continue
        
        var body := StaticBody3D.new()
        body.name = collision_name
        body.collision_layer = collision_layer
        body.collision_mask = collision_mask
        var shape := CollisionShape3D.new()
        var concave := ConcavePolygonShape3D.new()
        concave.data = faces
        shape.shape = concave
        body.add_child(shape)
        mesh.add_child(body)
        
        # Обрабатываем порциями для оптимизации на Mobile
        processed += 1
        if processed >= batch_size:
            processed = 0
            if get_tree() != null:
                await get_tree().process_frame

func collect_meshes(node: Node, out: Array[MeshInstance3D]) -> void:
    var mesh: MeshInstance3D = node as MeshInstance3D
    if mesh != null:
        out.append(mesh)
    for child in node.get_children():
        collect_meshes(child, out)

func is_decorative_object(mesh: MeshInstance3D) -> bool:
    if mesh == null:
        return false
    var name_lower := String(mesh.name).to_lower()
    # Проверяем имя на наличие ключевых слов декоративных объектов
    var decorative_keywords := [
        "grass", "bush", "foliage", "plant", "tree", 
        "flower", "shrub", "vegetation", "decoration", "decorative"
    ]
    for keyword in decorative_keywords:
        if name_lower.contains(keyword):
            return true
    # Проверяем имя родителя
    var parent := mesh.get_parent()
    if parent != null:
        var parent_name_lower := String(parent.name).to_lower()
        for keyword in decorative_keywords:
            if parent_name_lower.contains(keyword):
                return true
    return false

func is_tall_enough(mesh: MeshInstance3D) -> bool:
    if mesh == null or mesh.mesh == null:
        return false
    var aabb := mesh.mesh.get_aabb()
    # Если меш слишком маленький по высоте, скорее всего это трава/куст
    if aabb.size.y < min_collision_height:
        return false
    return true
