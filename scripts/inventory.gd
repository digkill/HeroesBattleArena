extends RefCounted
class_name Inventory

signal changed

var size := 3
var items: Array[String] = []

func has_space() -> bool:
    return items.size() < size

func add_item(item_id: String) -> bool:
    if not has_space():
        return false
    items.append(item_id)
    emit_signal("changed")
    return true

func remove_item(slot_index: int) -> String:
    if slot_index < 0 or slot_index >= items.size():
        return ""
    var item_id := items[slot_index]
    items.remove_at(slot_index)
    emit_signal("changed")
    return item_id

func get_item(slot_index: int) -> String:
    if slot_index < 0 or slot_index >= items.size():
        return ""
    return items[slot_index]
