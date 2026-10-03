extends CharacterBody3D

# =========================================================
# ZOMBIE TYPES
# =========================================================

enum ZombieType {
	RUNNER,
	STALKER,
	NORMAL,
	BERSERKER,
	BRUTE,
	TANK
}

var zombie_type: ZombieType = ZombieType.NORMAL

# =========================================================
# GENERAL SETTINGS
# =========================================================

const GRAVITY = 18.0
const ROTATION_SPEED = 5.0

var SPEED = 3.8
var MAX_HEALTH = 5
var DAMAGE = 1
var STOP_DISTANCE = 1.8

var health = 5

var player = null
var animation_player: AnimationPlayer = null

# =========================================================
# AI SETTINGS
# =========================================================

var direction_change_timer = 0.0
var strafe_direction = 1.0
var strafe_strength = 0.0

var attack_cooldown = 0.0

var is_enraged = false

# =========================================================
# AUDIO
# =========================================================

var zombie_sound: AudioStreamWAV
var zombie_attack_sound: AudioStreamWAV

var zombie_sound_timer = 0.0
var next_zombie_sound = 0.0


# =========================================================
# READY
# =========================================================

func _ready():

	randomize()

	animation_player = find_child(
		"AnimationPlayer",
		true,
		false
	) as AnimationPlayer

	player = get_tree().current_scene.get_node_or_null(
		"player"
	)

	choose_zombie_type()

	apply_zombie_type()

	zombie_sound = create_zombie_sound()
	zombie_attack_sound = create_zombie_attack_sound()

	next_zombie_sound = randf_range(
		2.0,
		5.0
	)

	if animation_player != null:

		if animation_player.has_animation(
			"mixamo_com"
		):

			animation_player.play(
				"mixamo_com"
			)

	print(
		"=============================="
	)

	print(
		"ZOMBIE TYPE: ",
		get_zombie_type_name()
	)

	print(
		"HP: ",
		health
	)

	print(
		"SPEED: ",
		SPEED
	)

	print(
		"=============================="
	)


# =========================================================
# CHOOSE TYPE
# =========================================================

func choose_zombie_type():

	var chance = randf()

	if chance < 0.25:

		zombie_type = ZombieType.RUNNER

	elif chance < 0.40:

		zombie_type = ZombieType.STALKER

	elif chance < 0.70:

		zombie_type = ZombieType.NORMAL

	elif chance < 0.82:

		zombie_type = ZombieType.BERSERKER

	elif chance < 0.95:

		zombie_type = ZombieType.BRUTE

	else:

		zombie_type = ZombieType.TANK


# =========================================================
# APPLY TYPE
# =========================================================

func apply_zombie_type():

	var holder = get_node_or_null(
		"holder"
	)

	if holder == null:

		print(
			"ERROR: holder مش موجود داخل Zombie"
		)

		return


	match zombie_type:

		# =================================================
		# RUNNER
		# =================================================

		ZombieType.RUNNER:

			SPEED = 5.5

			MAX_HEALTH = 3

			DAMAGE = 1

			STOP_DISTANCE = 1.6

			health = MAX_HEALTH

			holder.scale = Vector3(
				10.0,
				10.0,
				10.0
			)

			strafe_strength = 0.15


		# =================================================
		# STALKER
		# =================================================

		ZombieType.STALKER:

			SPEED = 3.2

			MAX_HEALTH = 4

			DAMAGE = 1

			STOP_DISTANCE = 2.0

			health = MAX_HEALTH

			holder.scale = Vector3(
				13.0,
				13.0,
				13.0
			)

			strafe_strength = 0.45


		# =================================================
		# NORMAL
		# =================================================

		ZombieType.NORMAL:

			SPEED = 3.8

			MAX_HEALTH = 5

			DAMAGE = 1

			STOP_DISTANCE = 1.8

			health = MAX_HEALTH

			holder.scale = Vector3(
				15.0,
				15.0,
				15.0
			)

			strafe_strength = 0.04


		# =================================================
		# BERSERKER
		# =================================================

		ZombieType.BERSERKER:

			SPEED = 4.2

			MAX_HEALTH = 7

			DAMAGE = 1

			STOP_DISTANCE = 1.9

			health = MAX_HEALTH

			holder.scale = Vector3(
				17.0,
				17.0,
				17.0
			)

			strafe_strength = 0.18


		# =================================================
		# BRUTE
		# =================================================

		ZombieType.BRUTE:

			SPEED = 2.5

			MAX_HEALTH = 9

			DAMAGE = 1

			STOP_DISTANCE = 2.1

			health = MAX_HEALTH

			holder.scale = Vector3(
				20.0,
				20.0,
				20.0
			)

			strafe_strength = 0.0


		# =================================================
		# TANK
		# =================================================

		ZombieType.TANK:

			SPEED = 1.7

			MAX_HEALTH = 12

			DAMAGE = 2

			STOP_DISTANCE = 2.3

			health = MAX_HEALTH

			holder.scale = Vector3(
				24.0,
				24.0,
				24.0
			)

			strafe_strength = 0.0


# =========================================================
# PHYSICS
# =========================================================

func _physics_process(delta):

	if not is_on_floor():

		velocity.y -= (
			GRAVITY *
			delta
		)

	else:

		velocity.y = 0.0


	# =====================================================
	# FIND PLAYER
	# =====================================================

	if player == null:

		player = get_tree().current_scene.get_node_or_null(
			"player"
		)

		if player == null:

			velocity.x = 0.0
			velocity.z = 0.0

			move_and_slide()

			return


	# =====================================================
	# TIMERS
	# =====================================================

	direction_change_timer -= delta
	attack_cooldown -= delta


	# =====================================================
	# DIRECTION TO PLAYER
	# =====================================================

	var to_player = (
		player.global_position -
		global_position
	)

	to_player.y = 0.0

	var distance = to_player.length()


	if distance < 0.01:

		move_and_slide()

		return


	var direction = to_player.normalized()


	# =====================================================
	# BERSERKER ENRAGE
	# =====================================================

	if zombie_type == ZombieType.BERSERKER:

		if health <= MAX_HEALTH * 0.45:

			if not is_enraged:

				is_enraged = true

				SPEED = 5.8

				print(
					"BERSERKER ENRAGED!"
				)


	# =====================================================
	# ATTACK
	# =====================================================

	if distance <= STOP_DISTANCE:

		velocity.x = move_toward(
			velocity.x,
			0.0,
			SPEED * 5.0 * delta
		)

		velocity.z = move_toward(
			velocity.z,
			0.0,
			SPEED * 5.0 * delta
		)

		face_player(
			direction,
			delta
		)

		if attack_cooldown <= 0.0:

			attack_player()


	# =====================================================
	# MOVEMENT
	# =====================================================

	else:

		var movement_direction = direction


		# =================================================
		# RUNNER AI
		# =================================================

		if zombie_type == ZombieType.RUNNER:

			var side = Vector3(
				-direction.z,
				0.0,
				direction.x
			)

			var wave = sin(
				Time.get_ticks_msec() *
				0.006
			)

			movement_direction += (
				side *
				wave *
				0.15
			)


		# =================================================
		# STALKER AI
		# =================================================

		elif zombie_type == ZombieType.STALKER:

			if direction_change_timer <= 0.0:

				direction_change_timer = randf_range(
					0.8,
					1.6
				)

				if randf() < 0.5:

					strafe_direction = -1.0

				else:

					strafe_direction = 1.0


			var side = Vector3(
				-direction.z,
				0.0,
				direction.x
			)

			movement_direction += (
				side *
				strafe_direction *
				strafe_strength
			)


		# =================================================
		# BERSERKER AI
		# =================================================

		elif zombie_type == ZombieType.BERSERKER:

			var side = Vector3(
				-direction.z,
				0.0,
				direction.x
			)

			var wave = sin(
				Time.get_ticks_msec() *
				0.007
			)

			movement_direction += (
				side *
				wave *
				strafe_strength
			)


		# =================================================
		# BRUTE AI
		# =================================================

		elif zombie_type == ZombieType.BRUTE:

			movement_direction = direction


		# =================================================
		# TANK AI
		# =================================================

		elif zombie_type == ZombieType.TANK:

			movement_direction = direction


		movement_direction.y = 0.0

		movement_direction = (
			movement_direction.normalized()
		)


		velocity.x = (
			movement_direction.x *
			SPEED
		)

		velocity.z = (
			movement_direction.z *
			SPEED
		)


		face_player(
			direction,
			delta
		)


	# =====================================================
	# ANIMATION
	# =====================================================

	if animation_player != null:

		if not animation_player.is_playing():

			if animation_player.has_animation(
				"mixamo_com"
			):

				animation_player.play(
					"mixamo_com"
				)


	# =====================================================
	# RANDOM ZOMBIE SOUND
	# =====================================================

	zombie_sound_timer += delta

	if zombie_sound_timer >= next_zombie_sound:

		zombie_sound_timer = 0.0

		next_zombie_sound = randf_range(
			3.0,
			7.0
		)

		play_zombie_sound()


	move_and_slide()


# =========================================================
# FACE PLAYER
# =========================================================

func face_player(
	direction: Vector3,
	delta: float
):

	if direction.length() <= 0.01:

		return


	var target_angle = atan2(
		direction.x,
		direction.z
	)


	rotation.y = lerp_angle(
		rotation.y,
		target_angle,
		ROTATION_SPEED *
		delta
	)


# =========================================================
# ATTACK
# =========================================================

func attack_player():

	if player == null:

		return


	attack_cooldown = 1.0

	play_attack_sound()

	if player.has_method(
		"take_damage"
	):

		player.take_damage(
			DAMAGE
		)


# =========================================================
# TAKE DAMAGE
# =========================================================

func take_damage(damage):

	health -= damage

	print(
		get_zombie_type_name(),
		" HP: ",
		health
	)


	if zombie_type == ZombieType.BERSERKER:

		if health <= MAX_HEALTH * 0.45:

			if not is_enraged:

				is_enraged = true

				SPEED = 5.8

				print(
					"BERSERKER ENRAGED!"
				)


	if health <= 0:

		die()


# =========================================================
# DIE
# =========================================================

func die():

	print(
		"Zombie مات: ",
		get_zombie_type_name()
	)


	if player != null:

		if player.has_method(
			"register_kill"
		):

			player.register_kill()


	queue_free()


# =========================================================
# TYPE NAME
# =========================================================

func get_zombie_type_name():

	match zombie_type:

		ZombieType.RUNNER:
			return "RUNNER"

		ZombieType.STALKER:
			return "STALKER"

		ZombieType.NORMAL:
			return "NORMAL"

		ZombieType.BERSERKER:
			return "BERSERKER"

		ZombieType.BRUTE:
			return "BRUTE"

		ZombieType.TANK:
			return "TANK"

	return "UNKNOWN"


# =========================================================
# ZOMBIE SOUND
# =========================================================

func play_zombie_sound():

	if zombie_sound == null:

		return


	var audio_player = AudioStreamPlayer3D.new()

	add_child(
		audio_player
	)

	audio_player.stream = zombie_sound

	audio_player.volume_db = -4.0

	audio_player.max_distance = 35.0

	audio_player.unit_size = 4.0

	audio_player.play()

	audio_player.finished.connect(
		audio_player.queue_free
	)


# =========================================================
# ATTACK SOUND
# =========================================================

func play_attack_sound():

	if zombie_attack_sound == null:

		return


	var audio_player = AudioStreamPlayer3D.new()

	add_child(
		audio_player
	)

	audio_player.stream = zombie_attack_sound

	audio_player.volume_db = -2.0

	audio_player.max_distance = 25.0

	audio_player.unit_size = 4.0

	audio_player.play()

	audio_player.finished.connect(
		audio_player.queue_free
	)


# =========================================================
# ZOMBIE SOUND
# =========================================================

func create_zombie_sound() -> AudioStreamWAV:

	var sample_rate = 22050
	var duration = 1.15

	var samples = int(
		sample_rate *
		duration
	)

	var data = PackedByteArray()

	data.resize(
		samples * 2
	)


	for i in range(samples):

		var t = float(i) / sample_rate

		var frequency = (
			85.0 +
			sin(t * 4.0) *
			18.0
		)

		var voice = sin(
			TAU *
			frequency *
			t
		)

		var voice2 = sin(
			TAU *
			(frequency * 1.47) *
			t
		)

		var noise = randf_range(
			-1.0,
			1.0
		)

		var envelope = 1.0


		if t < 0.15:

			envelope = (
				t /
				0.15
			)


		if t > duration - 0.35:

			envelope = (
				(duration - t) /
				0.35
			)


		var value = (
			voice * 0.55 +
			voice2 * 0.25 +
			noise * 0.12
		)

		value *= envelope
		value *= 0.45


		var sample = int(
			clamp(
				value * 32767.0,
				-32768.0,
				32767.0
			)
		)


		data.encode_s16(
			i * 2,
			sample
		)


	var audio = AudioStreamWAV.new()

	audio.format = (
		AudioStreamWAV.FORMAT_16_BITS
	)

	audio.mix_rate = sample_rate

	audio.stereo = false

	audio.data = data

	return audio


# =========================================================
# ATTACK SOUND
# =========================================================

func create_zombie_attack_sound() -> AudioStreamWAV:

	var sample_rate = 22050
	var duration = 0.35

	var samples = int(
		sample_rate *
		duration
	)

	var data = PackedByteArray()

	data.resize(
		samples * 2
	)


	for i in range(samples):

		var t = float(i) / sample_rate

		var frequency = (
			160.0 -
			(
				70.0 *
				t /
				duration
			)
		)

		var voice = sin(
			TAU *
			frequency *
			t
		)

		var noise = randf_range(
			-1.0,
			1.0
		)

		var envelope = (
			1.0 -
			t /
			duration
		)

		var value = (
			voice * 0.6 +
			noise * 0.35
		)

		value *= envelope
		value *= 0.5


		var sample = int(
			clamp(
				value * 32767.0,
				-32768.0,
				32767.0
			)
		)


		data.encode_s16(
			i * 2,
			sample
		)


	var audio = AudioStreamWAV.new()

	audio.format = (
		AudioStreamWAV.FORMAT_16_BITS
	)

	audio.mix_rate = sample_rate

	audio.stereo = false

	audio.data = data

	return audio
