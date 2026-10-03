extends Node3D

@export var zombie_scene: PackedScene
@export var max_zombies: int = 10
@export var spawn_interval: float = 3.0
@export var min_spawn_distance: float = 8.0
@export var max_spawn_distance: float = 40.0
@export var min_zombie_distance: float = 4.0

var player = null
var spawn_timer: float = 0.0


func _ready():
	player = get_tree().current_scene.get_node_or_null("player")

	if player == null:
		print("ERROR: player مش موجود")
		return

	for i in range(3):
		spawn_zombie()
		await get_tree().create_timer(0.3).timeout


func _process(delta):
	spawn_timer += delta

	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0

		if get_zombie_count() < max_zombies:
			spawn_zombie()


func spawn_zombie():

	if zombie_scene == null:
		print("ERROR: Zombie Scene مش متعين!")
		return

	if player == null:
		player = get_tree().current_scene.get_node_or_null("player")

	if player == null:
		return

	for attempt in range(50):

		var spawn_position = get_random_spawn_position()

		if spawn_position == null:
			continue

		var distance_to_player = spawn_position.distance_to(
			player.global_position
		)

		if distance_to_player < min_spawn_distance:
			continue

		if distance_to_player > max_spawn_distance:
			continue

		if too_close_to_other_zombie(spawn_position):
			continue

		var zombie = zombie_scene.instantiate()

		get_tree().current_scene.add_child(zombie)

		zombie.global_position = spawn_position

		print("Zombie Spawned")

		return

	print("لم أجد مكان Spawn مناسب")


func get_random_spawn_position():

	var floor_node = get_tree().current_scene.get_node_or_null("FLOOR")

	if floor_node == null:
		print("ERROR: FLOOR مش موجود")
		return null

	var mesh = floor_node.find_child(
		"MeshInstance3D",
		true,
		false
	)

	if mesh != null:

		var aabb = mesh.get_aabb()

		var x = randf_range(
			aabb.position.x,
			aabb.position.x + aabb.size.x
		)

		var z = randf_range(
			aabb.position.z,
			aabb.position.z + aabb.size.z
		)

		var local_position = Vector3(
			x,
			0.0,
			z
		)

		return mesh.to_global(local_position)

	return floor_node.global_position + Vector3(
		randf_range(-20.0, 20.0),
		1.0,
		randf_range(-20.0, 20.0)
	)


func too_close_to_other_zombie(position_to_check: Vector3) -> bool:

	for child in get_tree().current_scene.get_children():

		if child is CharacterBody3D:

			if child.name.to_lower().begins_with("zombi"):

				if position_to_check.distance_to(
					child.global_position
				) < min_zombie_distance:

					return true

	return false


func get_zombie_count() -> int:

	var count = 0

	for child in get_tree().current_scene.get_children():

		if child is CharacterBody3D:

			if child.name.to_lower().begins_with("zombi"):

				count += 1

	return count
