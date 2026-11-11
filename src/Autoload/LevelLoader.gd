extends Node
# Loads and unloads levels

var _game: Node = null
var _player: Player = null
var _level: Node2D = null

onready var scene_tree := get_tree()


func setup(game: Node, player: Player, Level: PackedScene) -> void:
	_game = game
	_player = player
	trigger(Level)


func trigger(NewLevel: PackedScene, portal_name: String = "") -> void:
	if _level:
		scene_tree.paused = true
		_game.transition.fade_to_black()
		yield(_game.transition, "faded_to_black")
		_level.queue_free()
		yield(_level, "tree_exited")

	_game.remove_child(_player)
	_level = NewLevel.instance()

	var checkpoints: Node = _level.get_node("Checkpoints")
	var start_checkpoint: Area2D = checkpoints.get_child(0)
	_player.last_checkpoint = start_checkpoint

	var player_position_node: Node2D = (
		start_checkpoint
		if portal_name.empty()
		else _level.get_node("Portals/%s" % portal_name)
	)
	_player.global_position = player_position_node.global_position
	_player.has_teleported = not portal_name.empty()

	# Restore visited checkpoints and keep the most recently visited one
	# as the respawn point when returning to a level.
	for checkpoint_name in _game.visited_checkpoints.get(_level.name, []):
		var checkpoint: Area2D = checkpoints.get_node(checkpoint_name)
		checkpoint.is_visited = true
		_player.last_checkpoint = checkpoint

	_game.level = _level
	_game.add_child(_level)
	_game.add_child(_player)

	_game.transition.fade_back_in()

	scene_tree.paused = false
