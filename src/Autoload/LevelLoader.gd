extends Node
# Loads and unloads levels.

signal level_loaded(level)

var _game: Node = null
var _player: Player = null
var _level: Node2D = null

onready var scene_tree := get_tree()


func setup(game: Node, player: Player, Level: PackedScene) -> void:
	if not is_instance_valid(game) or not is_instance_valid(player) or Level == null:
		push_error("LevelLoader.setup requires a game, player, and valid level scene.")
		return
	_game = game
	_player = player
	trigger(Level)


func trigger(NewLevel: PackedScene, portal_name: String = "") -> void:
	if not is_instance_valid(_game) or not is_instance_valid(_player) or NewLevel == null:
		push_error("LevelLoader.trigger called before setup or without a valid level scene.")
		return

	if is_instance_valid(_level):
		scene_tree.paused = true
		var transition = _game.get_node_or_null("UI/Transition")
		if is_instance_valid(transition):
			transition.fade_to_black()
			yield(transition, "faded_to_black")
		_level.queue_free()
		yield(_level, "tree_exited")

	var new_level := NewLevel.instance() as Node2D
	if not is_instance_valid(new_level):
		push_error("LevelLoader could not instance the requested level.")
		scene_tree.paused = false
		return

	var checkpoints := new_level.get_node_or_null("Checkpoints")
	if checkpoints == null or checkpoints.get_child_count() == 0:
		push_error("LevelLoader: the level must contain at least one Checkpoints child.")
		new_level.free()
		scene_tree.paused = false
		return

	var start_checkpoint := checkpoints.get_child(0) as Area2D
	if start_checkpoint == null:
		push_error("LevelLoader: the first checkpoint must be an Area2D.")
		new_level.free()
		scene_tree.paused = false
		return

	_game.remove_child(_player)
	_level = new_level
	_player.last_checkpoint = start_checkpoint

	var player_position_node: Node2D = start_checkpoint
	if not portal_name.empty():
		player_position_node = _level.get_node_or_null("Portals/%s" % portal_name) as Node2D
		if player_position_node == null:
			push_error("LevelLoader: portal '%s' was not found." % portal_name)
			_game.add_child(_player)
			_level.free()
			_level = null
			scene_tree.paused = false
			return

	_player.global_position = player_position_node.global_position
	_player.has_teleported = not portal_name.empty()

	# Restore visited checkpoints and keep the most recently visited one
	# as the respawn point when returning to a level.
	for checkpoint_name in _game.visited_checkpoints.get(_level.name, []):
		var checkpoint := checkpoints.get_node_or_null(checkpoint_name) as Area2D
		if checkpoint == null:
			continue
		checkpoint.is_visited = true
		_player.last_checkpoint = checkpoint

	_game.level = _level
	_game.add_child(_level)
	_game.add_child(_player)
	scene_tree.paused = false
	emit_signal("level_loaded", _level)
