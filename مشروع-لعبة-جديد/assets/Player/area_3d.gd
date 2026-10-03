extends Area3D

const SPEED = 40.0
const DAMAGE = 1
const LIFE_TIME = 3.0

var direction: Vector3 = Vector3.ZERO


func _ready():

	get_tree().create_timer(
		LIFE_TIME
	).timeout.connect(
		queue_free
	)


# =========================================================
# SET DIRECTION
# =========================================================

func setup_direction(
	new_direction: Vector3
):

	direction = (
		new_direction.normalized()
	)


# =========================================================
# BULLET MOVEMENT
# =========================================================

func _physics_process(delta):

	if direction == Vector3.ZERO:

		return

	var old_position = global_position

	var new_position = (
		old_position +
		direction *
		SPEED *
		delta
	)

	var space_state = (
		get_world_3d()
		.direct_space_state
	)

	var query = PhysicsRayQueryParameters3D.create(
		old_position,
		new_position
	)

	query.collision_mask = 0xFFFFFFFF

	query.collide_with_bodies = true

	query.collide_with_areas = true


	# =====================================================
	# EXCLUDE PLAYER
	# =====================================================

	var player = (
		get_tree()
		.current_scene
		.get_node_or_null(
			"player"
		)
	)

	if player != null:

		query.exclude = [
			self,
			player
		]

	else:

		query.exclude = [
			self
		]


	# =====================================================
	# RAYCAST
	# =====================================================

	var result = (
		space_state
		.intersect_ray(
			query
		)
	)


	if result:

		var hit_object = result.collider

		print(
			"BULLET HIT: ",
			hit_object
		)


		# =================================================
		# FIND ZOMBIE
		# =================================================

		var zombie = find_zombie_parent(
			hit_object
		)


		if zombie != null:

			# =============================================
			# DAMAGE
			# =============================================

			var final_damage = DAMAGE


			if player != null:

				var ability_system = (
					player
					.get_node_or_null(
						"AbilitySystem"
					)
				)


				if ability_system != null:

					final_damage = int(
						DAMAGE *
						ability_system
						.get_damage_multiplier()
					)


			print(
				"================================"
			)

			print(
				"ZOMBIE HIT!"
			)

			print(
				"Base Damage: ",
				DAMAGE
			)

			print(
				"Final Damage: ",
				final_damage
			)

			print(
				"Zombie HP Before: ",
				zombie.health
			)


			# =============================================
			# DAMAGE ZOMBIE
			# =============================================

			if zombie.has_method(
				"take_damage"
			):

				zombie.take_damage(
					final_damage
				)


			print(
				"Zombie HP After: ",
				zombie.health
			)

			print(
				"================================"
			)


			# =============================================
			# PLAYER HIT EFFECT
			# =============================================

			if player != null:

				if player.has_method(
					"show_hit_marker"
				):

					player.show_hit_marker()


				if player.has_method(
					"show_hit_effect"
				):

					player.show_hit_effect()


			queue_free()

			return


		# =================================================
		# WALL / FLOOR
		# =================================================

		if hit_object is StaticBody3D:

			queue_free()

			return


	# =====================================================
	# MOVE
	# =====================================================

	global_position = new_position


# =========================================================
# FIND ZOMBIE PARENT
# =========================================================

func find_zombie_parent(
	object
):

	if object == null:

		return null


	var current = object


	while current != null:

		if current.has_method(
			"take_damage"
		):

			return current


		current = current.get_parent()


	return null
