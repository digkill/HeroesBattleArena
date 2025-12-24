extends NavigationRegion3D
class_name NavigationBaker

@export var source_root: NodePath
@export var bake_on_ready := true

func _ready() -> void:
	if bake_on_ready:
		call_deferred("bake_from_source")

func bake_from_source() -> void:
	if navigation_mesh == null:
		navigation_mesh = NavigationMesh.new()
	var source_node: Node
	if source_root != NodePath():
		source_node = get_node_or_null(source_root)
	else:
		source_node = get_parent()
	if source_node == null:
		return
	
	# Откладываем тяжелые операции на несколько кадров для Mobile
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Используем асинхронное выпекание для Mobile
	var data := NavigationMeshSourceGeometryData3D.new()
	NavigationServer3D.parse_source_geometry_data(navigation_mesh, data, source_node)
	
	# Даем еще один кадр перед выпеканием
	await get_tree().process_frame
	
	NavigationServer3D.bake_from_source_geometry_data(navigation_mesh, data)
	self.navigation_mesh = navigation_mesh
