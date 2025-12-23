extends Node3D
class_name MapCollision

@export var collision_layer := 1
@export var collision_mask := 1
@export var collision_name := "AutoCollision"
@export var build_on_ready := true

func _ready() -> void:
    if build_on_ready:
        build_colliders()

func build_colliders() -> void:
    var meshes: Array[MeshInstance3D] = []
    collect_meshes(self, meshes)
    for mesh in meshes:
        if mesh.mesh == null:
            continue
        if mesh.get_node_or_null(collision_name) != null:
            continue
        var faces: PackedVector3Array = mesh.mesh.get_faces()
        if faces.is_empty():
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

func collect_meshes(node: Node, out: Array[MeshInstance3D]) -> void:
    var mesh: MeshInstance3D = node as MeshInstance3D
    if mesh != null:
        out.append(mesh)
    for child in node.get_children():
        collect_meshes(child, out)
