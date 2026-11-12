extends SteeringBehavior2D
class_name FollowHeatmapBehavior2D
# Prefer the native heatmap when it is available, but keep swarmer steering
# functional on platforms/builds where the GDNative library was not compiled.

var _heatmap = null
var _last_point_index: int = INF
var _last_velocity := Vector2.ZERO


func _ready() -> void:
	_heatmap = get_tree().root.find_node("Heatmap", true, false)


func _calculate_steering_internal(steering: SteeringMotion2D) -> SteeringMotion2D:
	var actor := get_actor()

	# Native heatmap steering is optional. Never assert on its absence: Android
	# builds without the GDNative binary use a lightweight seek-to-player fallback.
	if is_instance_valid(_heatmap):
		var point_index: int = _heatmap.calculate_point_index_for_world_position(actor.global_position)
		if point_index != _last_point_index:
			_last_point_index = point_index
			var to_target: Vector2 = _heatmap.best_direction_for(actor.global_position, true)
			steering.velocity = to_target * controller.max_acceleration
			_last_velocity = steering.velocity
		else:
			steering.velocity = _last_velocity
	else:
		var player := get_tree().root.find_node("Player", true, false) as Node2D
		if not is_instance_valid(player):
			return steering.reset_values()
		steering.velocity = actor.global_position.direction_to(player.global_position) * controller.max_acceleration

	steering.angular_velocity = 0.0
	return steering
