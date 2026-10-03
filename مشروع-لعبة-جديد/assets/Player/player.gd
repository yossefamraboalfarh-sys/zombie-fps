extends CharacterBody3D

const MAX_SPEED = 8.0
const ACCELERATION = 16.0
const DECELERATION = 10.0
const JUMP_VELOCITY = 4.5

const CAMERA_BACK_AMOUNT = 0.45
const CAMERA_DOWN_AMOUNT = 0.10
const CAMERA_SMOOTH = 8.0

const NORMAL_FOV = 75.0
const SPEED_FOV = 92.0
const FOV_SMOOTH = 8.0

const BOB_AMOUNT = 0.035
const BOB_SPEED = 10.0

const MOUSE_SENSITIVITY = 0.0025
const MIN_LOOK_ANGLE = -70.0
const MAX_LOOK_ANGLE = 89.0

const MAX_BULLETS = 40
const SHOOT_RATE = 0.12

var bollet = preload("uid://dvcjhrgec0ofb")

var bollets_left = MAX_BULLETS
var shoot_cooldown = 0.0
var is_reloading = false

# =========================================================
# الصحة
# =========================================================

const MAX_HEALTH = 3
var health = MAX_HEALTH
var is_dead = false

const DAMAGE_COOLDOWN = 1.0
var damage_cooldown = 0.0

# =========================================================
# الإحصائيات
# =========================================================

var kills = 0
var score = 0
var survival_time = 0.0

# =========================================================
# Kill Streak / Adrenaline
# =========================================================

const KILL_STREAK_TIME = 5.0
const ADRENALINE_REQUIRED_KILLS = 5
const ADRENALINE_DURATION = 4.0

var kill_streak = 0
var kill_streak_timer = 0.0

var adrenaline_active = false
var adrenaline_timer = 0.0

# =========================================================
# الارتداد
# =========================================================

const RECOIL_CAMERA_UP = 0.018
const RECOIL_CAMERA_SIDE = 0.008
const RECOIL_RECOVERY = 12.0

var recoil_x = 0.0
var recoil_y = 0.0

const GUN_RECOIL_BACK = 0.055
const GUN_RECOIL_UP = 0.035
const GUN_RECOIL_RECOVERY = 14.0

var gun_recoil_amount = 0.0
var gun_recoil_rotation = 0.0

var gun_start_position = Vector3.ZERO
var gun_start_rotation = Vector3.ZERO

# =========================================================
# مراجع
# =========================================================

@onready var head = $head
@onready var camera = $head/Camera3D
@onready var gun: Node3D = $head/Camera3D/Gun

var gun_raycast: RayCast3D = null
var gun_animation: AnimationPlayer = null

# =========================================================
# Ability System
# =========================================================

var ability_system = null

# =========================================================
# حركة
# =========================================================

var current_speed = 0.0
var camera_start_position = Vector3.ZERO
var bob_time = 0.0
var camera_pitch = 0.0

# =========================================================
# HUD
# =========================================================

var ammo_label: Label
var health_label: Label
var crosshair: Label
var hit_marker: Label

var damage_flash: ColorRect
var vignette: ColorRect

var reload_label: Label
var status_label: Label

var health_bar_background: ColorRect
var health_bar: ColorRect

var ammo_bar_background: ColorRect
var ammo_bar: ColorRect

var top_line: ColorRect
var bottom_line: ColorRect

var kills_label: Label
var score_label: Label
var wave_label: Label
var timer_label: Label

var wave_announcement: Label
var warning_label: Label

var hit_effect: Label
var heartbeat_label: Label

# =========================================================
# Ability HUD
# =========================================================

var ability_panel: Panel
var sprint_label: Label
var damage_ability_label: Label
var streak_label: Label
var adrenaline_label: Label

# =========================================================
# أصوات
# =========================================================

var shoot_sound: AudioStreamWAV
var reload_sound: AudioStreamWAV
var damage_sound: AudioStreamWAV
var heartbeat_sound: AudioStreamWAV
var kill_sound: AudioStreamWAV

# =========================================================
# وميض السلاح
# =========================================================

var muzzle_light: OmniLight3D
var muzzle_flash_timer = 0.0

# =========================================================
# تأثيرات
# =========================================================

var hit_marker_timer = 0.0
var hit_effect_timer = 0.0
var reload_display_timer = 0.0
var low_health_time = 0.0
var hud_time = 0.0
var warning_time = 0.0

var heartbeat_timer = 0.0
var heartbeat_interval = 0.85

var wave_announcement_timer = 0.0

var ability_flash_timer = 0.0

# =========================================================
# READY
# =========================================================

func _ready():

	camera_start_position = camera.position
	camera.fov = NORMAL_FOV

	Input.set_mouse_mode(
		Input.MOUSE_MODE_CAPTURED
	)

	gun_start_position = gun.position
	gun_start_rotation = gun.rotation

	# =====================================================
	# AbilitySystem
	# =====================================================

	ability_system = get_node_or_null("AbilitySystem")

	if ability_system != null:
		print("========== ABILITY SYSTEM ==========")
		print("AbilitySystem FOUND")
		print("Q = Sprint")
		print("E = Double Damage")
		print("====================================")
	else:
		print("WARNING: AbilitySystem غير موجود")

	shoot_sound = create_shoot_sound()
	reload_sound = create_reload_sound()
	damage_sound = create_player_damage_sound()
	heartbeat_sound = create_heartbeat_sound()
	kill_sound = create_kill_sound()

	await get_tree().process_frame

	gun_raycast = gun.find_child(
		"RayCast3D",
		true,
		false
	) as RayCast3D

	gun_animation = gun.find_child(
		"AnimationPlayer",
		true,
		false
	) as AnimationPlayer

	print("")
	print("========== GUN DEBUG ==========")

	if gun_raycast != null:
		print("RayCast FOUND")
	else:
		print("ERROR: RayCast3D NOT FOUND")

	if gun_animation != null:
		print("AnimationPlayer FOUND")
	else:
		print("ERROR: AnimationPlayer NOT FOUND")

	print("================================")

	create_hud()
	create_crosshair()
	create_damage_effect()
	create_vignette()
	create_muzzle_flash()
	create_ability_hud()


# =========================================================
# INPUT
# =========================================================

func _unhandled_input(event):

	if is_dead:
		return

	if event is InputEventMouseMotion:

		rotate_y(
			-event.relative.x *
			MOUSE_SENSITIVITY
		)

		camera_pitch -= (
			event.relative.y *
			MOUSE_SENSITIVITY
		)

		camera_pitch = clamp(
			camera_pitch,
			deg_to_rad(MIN_LOOK_ANGLE),
			deg_to_rad(MAX_LOOK_ANGLE)
		)

		head.rotation.x = camera_pitch

	if event.is_action_pressed("ui_cancel"):

		Input.set_mouse_mode(
			Input.MOUSE_MODE_VISIBLE
		)

	if event is InputEventMouseButton:

		if event.pressed:

			Input.set_mouse_mode(
				Input.MOUSE_MODE_CAPTURED
			)


# =========================================================
# PHYSICS
# =========================================================

func _physics_process(delta):

	if is_dead:
		return

	hud_time += delta
	survival_time += delta

	if damage_cooldown > 0.0:
		damage_cooldown -= delta

	# =====================================================
	# Kill Streak
	# =====================================================

	if kill_streak > 0:

		kill_streak_timer -= delta

		if kill_streak_timer <= 0.0:

			kill_streak = 0

	# =====================================================
	# Adrenaline
	# =====================================================

	if adrenaline_active:

		adrenaline_timer -= delta

		if adrenaline_timer <= 0.0:

			adrenaline_active = false
			adrenaline_timer = 0.0

	# =====================================================
	# Ability Flash
	# =====================================================

	if ability_flash_timer > 0.0:

		ability_flash_timer -= delta

	# =====================================================
	# الجاذبية
	# =====================================================

	if not is_on_floor():

		velocity += get_gravity() * delta

	# =====================================================
	# القفز
	# =====================================================

	if Input.is_action_just_pressed("ui_accept"):

		if is_on_floor():

			velocity.y = JUMP_VELOCITY

	# =====================================================
	# الحركة
	# =====================================================

	var input_dir = Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_backward"
	)

	var direction = Vector3(
		input_dir.x,
		0,
		input_dir.y
	)

	direction = direction.normalized()

	if direction.length() > 0:

		current_speed = move_toward(
			current_speed,
			MAX_SPEED,
			ACCELERATION * delta
		)

	else:

		current_speed = move_toward(
			current_speed,
			0.0,
			DECELERATION * delta
		)

	# =====================================================
	# سرعة القدرات
	# =====================================================

	var ability_speed_multiplier = 1.0

	if ability_system != null:

		if ability_system.has_method(
			"get_speed_multiplier"
		):

			ability_speed_multiplier = (
				ability_system.get_speed_multiplier()
			)

	# =====================================================
	# Adrenaline +25%
	# =====================================================

	if adrenaline_active:

		ability_speed_multiplier *= 1.25

	var final_speed = (
		current_speed *
		ability_speed_multiplier
	)

	var world_direction = (
		transform.basis *
		direction
	)

	velocity.x = (
		world_direction.x *
		final_speed
	)

	velocity.z = (
		world_direction.z *
		final_speed
	)

	move_and_slide()

	# =====================================================
	# حركة الكاميرا
	# =====================================================

	var speed_ratio = (
		current_speed /
		MAX_SPEED
	)

	speed_ratio = clamp(
		speed_ratio,
		0.0,
		1.0
	)

	var target_camera_position = (
		camera_start_position
	)

	var look_down_factor = clamp(
		camera_pitch /
		deg_to_rad(-70.0),
		0.0,
		1.0
	)

	var camera_back = (
		CAMERA_BACK_AMOUNT *
		speed_ratio
	)

	camera_back *= (
		1.0 -
		look_down_factor
	)

	target_camera_position.z = (
		camera_start_position.z +
		camera_back
	)

	target_camera_position.y = (
		camera_start_position.y -
		CAMERA_DOWN_AMOUNT *
		speed_ratio
	)

	if current_speed > 0.1 and is_on_floor():

		bob_time += (
			delta *
			BOB_SPEED *
			speed_ratio
		)

		target_camera_position.y += (
			sin(bob_time) *
			BOB_AMOUNT *
			speed_ratio
		)

	else:

		bob_time = 0.0

	camera.position = camera.position.lerp(
		target_camera_position,
		CAMERA_SMOOTH * delta
	)

	# =====================================================
	# استرجاع الارتداد
	# =====================================================

	recoil_x = move_toward(
		recoil_x,
		0.0,
		RECOIL_RECOVERY * delta
	)

	recoil_y = move_toward(
		recoil_y,
		0.0,
		RECOIL_RECOVERY * delta
	)

	head.rotation.x += recoil_x * delta

	rotate_y(
		recoil_y * delta
	)

	# =====================================================
	# FOV
	# =====================================================

	var target_fov = lerp(
		NORMAL_FOV,
		SPEED_FOV,
		speed_ratio
	)

	if ability_speed_multiplier > 1.0:

		target_fov += (
			ability_speed_multiplier -
			1.0
		) * 12.0

	if adrenaline_active:

		target_fov += 7.0

	camera.fov = lerp(
		camera.fov,
		target_fov,
		FOV_SMOOTH * delta
	)

	# =====================================================
	# حركة السلاح
	# =====================================================

	gun_recoil_amount = move_toward(
		gun_recoil_amount,
		0.0,
		GUN_RECOIL_RECOVERY * delta
	)

	gun_recoil_rotation = move_toward(
		gun_recoil_rotation,
		0.0,
		GUN_RECOIL_RECOVERY * delta
	)

	gun.position = gun_start_position

	gun.position.z += (
		gun_recoil_amount
	)

	gun.position.y += (
		gun_recoil_amount *
		0.35
	)

	gun.rotation = gun_start_rotation

	gun.rotation.x -= (
		gun_recoil_rotation
	)

	# =====================================================
	# وميض الفوهة
	# =====================================================

	if muzzle_flash_timer > 0.0:

		muzzle_flash_timer -= delta

		if muzzle_flash_timer <= 0.0:

			if muzzle_light != null:

				muzzle_light.visible = false

	# =====================================================
	# Hit Marker
	# =====================================================

	if hit_marker_timer > 0.0:

		hit_marker_timer -= delta

		if hit_marker != null:

			hit_marker.modulate.a = clamp(
				hit_marker_timer * 8.0,
				0.0,
				1.0
			)

	# =====================================================
	# Hit Effect
	# =====================================================

	if hit_effect_timer > 0.0:

		hit_effect_timer -= delta

		if hit_effect != null:

			hit_effect.modulate.a = clamp(
				hit_effect_timer * 5.0,
				0.0,
				1.0
			)

	# =====================================================
	# Reload UI
	# =====================================================

	if reload_display_timer > 0.0:

		reload_display_timer -= delta

		if reload_display_timer <= 0.0:

			if reload_label != null:

				reload_label.modulate.a = 0.0

	# =====================================================
	# Wave Announcement
	# =====================================================

	if wave_announcement_timer > 0.0:

		wave_announcement_timer -= delta

		if wave_announcement != null:

			wave_announcement.modulate.a = clamp(
				wave_announcement_timer * 2.0,
				0.0,
				1.0
			)

	# =====================================================
	# إطلاق النار
	# =====================================================

	shoot_cooldown -= delta

	if not is_reloading:

		if Input.is_action_pressed("shoot"):

			if shoot_cooldown <= 0.0:

				if bollets_left > 0:

					shoot()

					shoot_cooldown = SHOOT_RATE

	# =====================================================
	# التعمير
	# =====================================================

	if Input.is_action_just_pressed("reload"):

		reload()

	# =====================================================
	# ضرر الزومبي
	# =====================================================

	check_zombie_damage()

	# =====================================================
	# Warning
	# =====================================================

	update_zombie_warning()

	# =====================================================
	# Heartbeat
	# =====================================================

	update_heartbeat(delta)

	# =====================================================
	# HUD
	# =====================================================

	update_hud()

	update_crosshair(
		speed_ratio
	)

	update_health_effect(
		delta
	)

	update_bars()

	update_effects(delta)

	update_ability_hud()


# =========================================================
# إطلاق النار
# =========================================================

func shoot():

	if is_reloading:
		return

	if bollets_left <= 0:
		return

	if gun_raycast == null:

		print(
			"ERROR: RayCast3D مش موجود"
		)

		return

	var bullet_instance = bollet.instantiate()

	if bullet_instance == null:
		return

	get_tree().current_scene.add_child(
		bullet_instance
	)

	bullet_instance.global_position = (
		gun_raycast.global_position
	)

	var shoot_direction = (
		-camera.global_transform.basis.z
	).normalized()

	if bullet_instance.has_method(
		"setup_direction"
	):

		bullet_instance.setup_direction(
			shoot_direction
		)

	bollets_left -= 1

	print(
		"تم إطلاق النار - المتبقي: ",
		bollets_left
	)

	play_sound(
		shoot_sound,
		-2.0
	)

	recoil_x -= RECOIL_CAMERA_UP

	recoil_y = randf_range(
		-RECOIL_CAMERA_SIDE,
		RECOIL_CAMERA_SIDE
	)

	gun_recoil_amount = GUN_RECOIL_BACK

	gun_recoil_rotation = (
		RECOIL_CAMERA_UP *
		2.5
	)

	if muzzle_light != null:

		muzzle_light.visible = true

		muzzle_light.light_energy = randf_range(
			3.0,
			5.0
		)

		muzzle_flash_timer = 0.045

	if gun_animation != null:

		if gun_animation.has_animation(
			"shoot"
		):

			if not gun_animation.is_playing():

				gun_animation.play(
					"shoot"
				)


# =========================================================
# التعمير
# =========================================================

func reload():

	if is_reloading:
		return

	if bollets_left >= MAX_BULLETS:

		print(
			"المخزن مليان بالفعل"
		)

		return

	if gun_animation == null:

		print(
			"ERROR: AnimationPlayer مش موجود"
		)

		return

	if not gun_animation.has_animation(
		"relod"
	):

		print(
			"ERROR: relod animation مش موجودة"
		)

		return

	is_reloading = true

	print(
		"Reload بدأ..."
	)

	play_sound(
		reload_sound,
		0.0
	)

	if reload_label != null:

		reload_label.text = "RELOADING..."

		reload_label.modulate.a = 1.0

		reload_display_timer = 2.0

	gun_animation.play(
		"relod"
	)

	await gun_animation.animation_finished

	if is_dead:
		return

	bollets_left = MAX_BULLETS

	is_reloading = false

	print(
		"Reload انتهى - الطلقات: ",
		bollets_left
	)

	if reload_label != null:

		reload_label.text = "READY"

		reload_display_timer = 0.7


# =========================================================
# ضرر اللاعب
# =========================================================

func take_damage(damage):

	if is_dead:
		return

	if damage_cooldown > 0.0:
		return

	damage_cooldown = DAMAGE_COOLDOWN

	health -= damage

	if health < 0:
		health = 0

	print(
		"Player HP: ",
		health
	)

	play_sound(
		damage_sound,
		0.0
	)

	if damage_flash != null:

		damage_flash.color = Color(
			0.9,
			0.0,
			0.0,
			0.45
		)

	update_hud()

	if health <= 0:

		player_died()


# =========================================================
# فحص ضرر الزومبي
# =========================================================

func check_zombie_damage():

	if damage_cooldown > 0.0:
		return

	var scene = get_tree().current_scene

	if scene == null:
		return

	for child in scene.get_children():

		if child is CharacterBody3D:

			if child.name.to_lower().begins_with(
				"zombi"
			):

				var areas = child.find_children(
					"*",
					"Area3D",
					true,
					false
				)

				for area in areas:

					if area is Area3D:

						if not area.monitoring:
							continue

						var bodies = (
							area.get_overlapping_bodies()
						)

						if self in bodies:

							if child.has_method(
								"play_attack_sound"
							):

								child.play_attack_sound()

							take_damage(1)

							return


# =========================================================
# Kill
# =========================================================

func register_kill():

	if is_dead:
		return

	kills += 1
	score += 100

	# =====================================================
	# Kill Streak
	# =====================================================

	kill_streak += 1
	kill_streak_timer = KILL_STREAK_TIME

	show_hit_marker()

	print(
		"KILL! ",
		kills,
		" SCORE: ",
		score,
		" STREAK: ",
		kill_streak
	)

	play_sound(
		kill_sound,
		-3.0
	)

	# =====================================================
	# Adrenaline
	# =====================================================

	if kill_streak >= ADRENALINE_REQUIRED_KILLS:

		kill_streak = 0

		adrenaline_active = true
		adrenaline_timer = ADRENALINE_DURATION

		ability_flash_timer = 0.5

		print(
			"🔥 ADRENALINE ACTIVATED!"
		)

	update_hud()


func show_hit_marker():

	if hit_marker == null:
		return

	hit_marker.modulate.a = 1.0

	hit_marker_timer = 0.22


func show_hit_effect():

	if hit_effect == null:
		return

	hit_effect.modulate.a = 1.0

	hit_effect_timer = 0.18


# =========================================================
# HUD
# =========================================================

func create_hud():

	var canvas = CanvasLayer.new()

	canvas.name = "GameHUD"

	add_child(canvas)

	# =====================================================
	# Ammo
	# =====================================================

	ammo_label = Label.new()

	ammo_label.name = "AmmoLabel"

	ammo_label.text = "40/40"

	ammo_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_RIGHT
	)

	ammo_label.add_theme_font_size_override(
		"font_size",
		28
	)

	ammo_label.add_theme_color_override(
		"font_color",
		Color.WHITE
	)

	ammo_label.set_anchors_preset(
		Control.PRESET_BOTTOM_RIGHT
	)

	ammo_label.offset_left = -210
	ammo_label.offset_top = -95
	ammo_label.offset_right = -25
	ammo_label.offset_bottom = -55

	canvas.add_child(
		ammo_label
	)

	# =====================================================
	# Health
	# =====================================================

	health_label = Label.new()

	health_label.name = "HealthLabel"

	health_label.text = "3/3"

	health_label.add_theme_font_size_override(
		"font_size",
		30
	)

	health_label.add_theme_color_override(
		"font_color",
		Color(
			1,
			0.12,
			0.12
		)
	)

	health_label.set_anchors_preset(
		Control.PRESET_BOTTOM_LEFT
	)

	health_label.offset_left = 25
	health_label.offset_top = -95
	health_label.offset_right = 120
	health_label.offset_bottom = -55

	canvas.add_child(
		health_label
	)

	# =====================================================
	# Kills
	# =====================================================

	kills_label = Label.new()

	kills_label.text = "KILLS  0"

	kills_label.add_theme_font_size_override(
		"font_size",
		20
	)

	kills_label.add_theme_color_override(
		"font_color",
		Color(
			1.0,
			0.75,
			0.15
		)
	)

	kills_label.set_anchors_preset(
		Control.PRESET_TOP_LEFT
	)

	kills_label.offset_left = 25
	kills_label.offset_top = 25
	kills_label.offset_right = 180
	kills_label.offset_bottom = 55

	canvas.add_child(
		kills_label
	)

	# =====================================================
	# Score
	# =====================================================

	score_label = Label.new()

	score_label.text = "SCORE  0"

	score_label.add_theme_font_size_override(
		"font_size",
		20
	)

	score_label.add_theme_color_override(
		"font_color",
		Color(
			0.95,
			0.95,
			0.95
		)
	)

	score_label.set_anchors_preset(
		Control.PRESET_TOP_LEFT
	)

	score_label.offset_left = 25
	score_label.offset_top = 55
	score_label.offset_right = 200
	score_label.offset_bottom = 85

	canvas.add_child(
		score_label
	)

	# =====================================================
	# Wave
	# =====================================================

	wave_label = Label.new()

	wave_label.text = "WAVE  1"

	wave_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	wave_label.add_theme_font_size_override(
		"font_size",
		24
	)

	wave_label.add_theme_color_override(
		"font_color",
		Color(
			1.0,
			0.2,
			0.2
		)
	)

	wave_label.set_anchors_preset(
		Control.PRESET_TOP_WIDE
	)

	wave_label.offset_top = 25
	wave_label.offset_bottom = 60

	canvas.add_child(
		wave_label
	)

	# =====================================================
	# Timer
	# =====================================================

	timer_label = Label.new()

	timer_label.text = "00:00"

	timer_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_RIGHT
	)

	timer_label.add_theme_font_size_override(
		"font_size",
		18
	)

	timer_label.add_theme_color_override(
		"font_color",
		Color(
			0.75,
			0.75,
			0.75
		)
	)

	timer_label.set_anchors_preset(
		Control.PRESET_TOP_RIGHT
	)

	timer_label.offset_left = -130
	timer_label.offset_top = 28
	timer_label.offset_right = -25
	timer_label.offset_bottom = 55

	canvas.add_child(
		timer_label
	)

	# =====================================================
	# الخطوط
	# =====================================================

	top_line = ColorRect.new()

	top_line.color = Color(
		0.75,
		0.0,
		0.0,
		0.45
	)

	top_line.set_anchors_preset(
		Control.PRESET_TOP_WIDE
	)

	top_line.offset_bottom = 2

	canvas.add_child(
		top_line
	)

	bottom_line = ColorRect.new()

	bottom_line.color = Color(
		0.75,
		0.0,
		0.0,
		0.25
	)

	bottom_line.set_anchors_preset(
		Control.PRESET_BOTTOM_WIDE
	)

	bottom_line.offset_top = -2

	canvas.add_child(
		bottom_line
	)

	# =====================================================
	# Reload
	# =====================================================

	reload_label = Label.new()

	reload_label.text = ""

	reload_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	reload_label.add_theme_font_size_override(
		"font_size",
		22
	)

	reload_label.add_theme_color_override(
		"font_color",
		Color(
			1.0,
			0.2,
			0.2
		)
	)

	reload_label.modulate.a = 0.0

	reload_label.set_anchors_preset(
		Control.PRESET_CENTER
	)

	reload_label.offset_left = -150
	reload_label.offset_top = 100
	reload_label.offset_right = 150
	reload_label.offset_bottom = 140

	canvas.add_child(
		reload_label
	)

	# =====================================================
	# Wave Announcement
	# =====================================================

	wave_announcement = Label.new()

	wave_announcement.text = "WAVE 1"

	wave_announcement.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	wave_announcement.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	wave_announcement.add_theme_font_size_override(
		"font_size",
		52
	)

	wave_announcement.add_theme_color_override(
		"font_color",
		Color(
			1.0,
			0.08,
			0.08
		)
	)

	wave_announcement.set_anchors_preset(
		Control.PRESET_CENTER
	)

	wave_announcement.offset_left = -250
	wave_announcement.offset_top = -80
	wave_announcement.offset_right = 250
	wave_announcement.offset_bottom = 0

	wave_announcement.modulate.a = 0.0

	canvas.add_child(
		wave_announcement
	)

	# =====================================================
	# Warning
	# =====================================================

	warning_label = Label.new()

	warning_label.text = "⚠ ENEMY NEARBY"

	warning_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	warning_label.add_theme_font_size_override(
		"font_size",
		18
	)

	warning_label.add_theme_color_override(
		"font_color",
		Color(
			1.0,
			0.05,
			0.05
		)
	)

	warning_label.set_anchors_preset(
		Control.PRESET_CENTER
	)

	warning_label.offset_left = -150
	warning_label.offset_top = 155
	warning_label.offset_right = 150
	warning_label.offset_bottom = 190

	warning_label.modulate.a = 0.0

	canvas.add_child(
		warning_label
	)

	# =====================================================
	# Heartbeat
	# =====================================================

	heartbeat_label = Label.new()

	heartbeat_label.text = "♥"

	heartbeat_label.add_theme_font_size_override(
		"font_size",
		34
	)

	heartbeat_label.add_theme_color_override(
		"font_color",
		Color(
			1.0,
			0.0,
			0.0
		)
	)

	heartbeat_label.set_anchors_preset(
		Control.PRESET_BOTTOM_LEFT
	)

	heartbeat_label.offset_left = 210
	heartbeat_label.offset_top = -78
	heartbeat_label.offset_right = 260
	heartbeat_label.offset_bottom = -38

	heartbeat_label.modulate.a = 0.0

	canvas.add_child(
		heartbeat_label
	)

	# =====================================================
	# Health Bar
	# =====================================================

	health_bar_background = ColorRect.new()

	health_bar_background.color = Color(
		0.05,
		0.05,
		0.05,
		0.85
	)

	health_bar_background.set_anchors_preset(
		Control.PRESET_BOTTOM_LEFT
	)

	health_bar_background.offset_left = 25
	health_bar_background.offset_top = -50
	health_bar_background.offset_right = 205
	health_bar_background.offset_bottom = -40

	canvas.add_child(
		health_bar_background
	)

	health_bar = ColorRect.new()

	health_bar.color = Color(
		0.85,
		0.02,
		0.02,
		1.0
	)

	health_bar.set_anchors_preset(
		Control.PRESET_BOTTOM_LEFT
	)

	health_bar.offset_left = 25
	health_bar.offset_top = -50
	health_bar.offset_right = 205
	health_bar.offset_bottom = -40

	canvas.add_child(
		health_bar
	)

	# =====================================================
	# Ammo Bar
	# =====================================================

	ammo_bar_background = ColorRect.new()

	ammo_bar_background.color = Color(
		0.05,
		0.05,
		0.05,
		0.85
	)

	ammo_bar_background.set_anchors_preset(
		Control.PRESET_BOTTOM_RIGHT
	)

	ammo_bar_background.offset_left = -205
	ammo_bar_background.offset_top = -50
	ammo_bar_background.offset_right = -25
	ammo_bar_background.offset_bottom = -40

	canvas.add_child(
		ammo_bar_background
	)

	ammo_bar = ColorRect.new()

	ammo_bar.color = Color(
		0.85,
		0.75,
		0.08,
		1.0
	)

	ammo_bar.set_anchors_preset(
		Control.PRESET_BOTTOM_RIGHT
	)

	ammo_bar.offset_left = -205
	ammo_bar.offset_top = -50
	ammo_bar.offset_right = -25
	ammo_bar.offset_bottom = -40

	canvas.add_child(
		ammo_bar
	)


# =========================================================
# Ability HUD
# =========================================================

func create_ability_hud():

	var canvas = get_node_or_null(
		"GameHUD"
	)

	if canvas == null:
		return

	# =====================================================
	# Sprint
	# =====================================================

	sprint_label = Label.new()

	sprint_label.name = "SprintAbility"

	sprint_label.text = "Q  ⚡ SPRINT"

	sprint_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	sprint_label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	sprint_label.add_theme_font_size_override(
		"font_size",
		18
	)

	sprint_label.add_theme_color_override(
		"font_color",
		Color(
			0.3,
			0.85,
			1.0
		)
	)

	sprint_label.set_anchors_preset(
		Control.PRESET_BOTTOM_WIDE
	)

	sprint_label.offset_left = -230
	sprint_label.offset_top = -92
	sprint_label.offset_right = -10
	sprint_label.offset_bottom = -50

	canvas.add_child(
		sprint_label
	)

	# =====================================================
	# Double Damage
	# =====================================================

	damage_ability_label = Label.new()

	damage_ability_label.name = "DamageAbility"

	damage_ability_label.text = "E  💥 DOUBLE DAMAGE"

	damage_ability_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	damage_ability_label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	damage_ability_label.add_theme_font_size_override(
		"font_size",
		18
	)

	damage_ability_label.add_theme_color_override(
		"font_color",
		Color(
			1.0,
			0.55,
			0.15
		)
	)

	damage_ability_label.set_anchors_preset(
		Control.PRESET_BOTTOM_WIDE
	)

	damage_ability_label.offset_left = 10
	damage_ability_label.offset_top = -92
	damage_ability_label.offset_right = 230
	damage_ability_label.offset_bottom = -50

	canvas.add_child(
		damage_ability_label
	)

	# =====================================================
	# Kill Streak
	# =====================================================

	streak_label = Label.new()

	streak_label.text = "🔥 STREAK 0/5"

	streak_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	streak_label.set_anchors_preset(
		Control.PRESET_BOTTOM_WIDE
	)

	streak_label.offset_left = -150
	streak_label.offset_top = -145
	streak_label.offset_right = 150
	streak_label.offset_bottom = -110

	streak_label.add_theme_font_size_override(
		"font_size",
		18
	)

	canvas.add_child(
		streak_label
	)

	# =====================================================
	# Adrenaline
	# =====================================================

	adrenaline_label = Label.new()

	adrenaline_label.text = "🔥 ADRENALINE"

	adrenaline_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	adrenaline_label.set_anchors_preset(
		Control.PRESET_CENTER
	)

	adrenaline_label.offset_left = -180
	adrenaline_label.offset_top = 55
	adrenaline_label.offset_right = 180
	adrenaline_label.offset_bottom = 100

	adrenaline_label.add_theme_font_size_override(
		"font_size",
		24
	)

	adrenaline_label.add_theme_color_override(
		"font_color",
		Color(
			1.0,
			0.35,
			0.05
		)
	)

	adrenaline_label.modulate.a = 0.0

	canvas.add_child(
		adrenaline_label
	)


# =========================================================
# Update Ability HUD
# =========================================================

func update_ability_hud():

	if ability_system == null:

		if sprint_label != null:
			sprint_label.text = "Q  ⚡ SPRINT"

		if damage_ability_label != null:
			damage_ability_label.text = "E  💥 DOUBLE DAMAGE"

		return

	# =====================================================
	# Sprint
	# =====================================================

	var sprint_active = false
	var sprint_cooldown = 0.0
	var sprint_active_time = 0.0

	if "sprint_active" in ability_system:
		sprint_active = ability_system.sprint_active

	if "sprint_cooldown_left" in ability_system:
		sprint_cooldown = ability_system.sprint_cooldown_left

	if "sprint_active_left" in ability_system:
		sprint_active_time = ability_system.sprint_active_left

	if sprint_label != null:

		if sprint_active:

			sprint_label.text = (
				"Q  ⚡ SPRINT  " +
				str(round(sprint_active_time * 10.0) / 10.0) +
				"s"
			)

			sprint_label.add_theme_color_override(
				"font_color",
				Color(
					0.2,
					1.0,
					1.0
				)
			)

		elif sprint_cooldown > 0.0:

			sprint_label.text = (
				"Q  ⚡ READY IN " +
				str(round(sprint_cooldown * 10.0) / 10.0) +
				"s"
			)

			sprint_label.add_theme_color_override(
				"font_color",
				Color(
					0.45,
					0.45,
					0.45
				)
			)

		else:

			sprint_label.text = "Q  ⚡ SPRINT  READY"

			sprint_label.add_theme_color_override(
				"font_color",
				Color(
					0.3,
					0.85,
					1.0
				)
			)

	# =====================================================
	# Double Damage
	# =====================================================

	var damage_active = false
	var damage_cooldown_left = 0.0
	var damage_active_left = 0.0

	if "damage_active" in ability_system:
		damage_active = ability_system.damage_active

	if "damage_cooldown_left" in ability_system:
		damage_cooldown_left = (
			ability_system.damage_cooldown_left
		)

	if "damage_active_left" in ability_system:
		damage_active_left = (
			ability_system.damage_active_left
		)

	if damage_ability_label != null:

		if damage_active:

			damage_ability_label.text = (
				"E  💥 DOUBLE DAMAGE  " +
				str(round(damage_active_left * 10.0) / 10.0) +
				"s"
			)

			damage_ability_label.add_theme_color_override(
				"font_color",
				Color(
					1.0,
					0.25,
					0.05
				)
			)

		elif damage_cooldown_left > 0.0:

			damage_ability_label.text = (
				"E  💥 READY IN " +
				str(round(damage_cooldown_left * 10.0) / 10.0) +
				"s"
			)

			damage_ability_label.add_theme_color_override(
				"font_color",
				Color(
					0.45,
					0.45,
					0.45
				)
			)

		else:

			damage_ability_label.text = (
				"E  💥 DOUBLE DAMAGE  READY"
			)

			damage_ability_label.add_theme_color_override(
				"font_color",
				Color(
					1.0,
					0.55,
					0.15
				)
			)

	# =====================================================
	# Kill Streak
	# =====================================================

	if streak_label != null:

		if adrenaline_active:

			streak_label.text = (
				"🔥 ADRENALINE  " +
				str(round(adrenaline_timer * 10.0) / 10.0) +
				"s"
			)

			streak_label.add_theme_color_override(
				"font_color",
				Color(
					1.0,
					0.3,
					0.05
				)
			)

		else:

			streak_label.text = (
				"🔥 STREAK " +
				str(kill_streak) +
				"/" +
				str(ADRENALINE_REQUIRED_KILLS)
			)

			streak_label.add_theme_color_override(
				"font_color",
				Color(
					1.0,
					0.75,
					0.15
				)
			)

	# =====================================================
	# Adrenaline
	# =====================================================

	if adrenaline_label != null:

		if adrenaline_active:

			adrenaline_label.modulate.a = (
				0.7 +
				sin(hud_time * 12.0) * 0.3
			)

			adrenaline_label.text = (
				"🔥 ADRENALINE  +" +
				"25% SPEED   " +
				str(round(adrenaline_timer * 10.0) / 10.0) +
				"s"
			)

		else:

			adrenaline_label.modulate.a = move_toward(
				adrenaline_label.modulate.a,
				0.0,
				0.08
			)


# =========================================================
# Crosshair
# =========================================================

func create_crosshair():

	crosshair = Label.new()

	crosshair.text = "·"

	crosshair.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	crosshair.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	crosshair.add_theme_font_size_override(
		"font_size",
		28
	)

	crosshair.add_theme_color_override(
		"font_color",
		Color(
			1,
			1,
			1,
			0.9
		)
	)

	crosshair.set_anchors_preset(
		Control.PRESET_CENTER
	)

	crosshair.offset_left = -25
	crosshair.offset_top = -25
	crosshair.offset_right = 25
	crosshair.offset_bottom = 25

	var canvas = get_node_or_null(
		"GameHUD"
	)

	if canvas != null:

		canvas.add_child(
			crosshair
		)

	hit_marker = Label.new()

	hit_marker.text = "✕"

	hit_marker.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	hit_marker.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	hit_marker.add_theme_font_size_override(
		"font_size",
		30
	)

	hit_marker.add_theme_color_override(
		"font_color",
		Color(
			1,
			0.15,
			0.15,
			1
		)
	)

	hit_marker.set_anchors_preset(
		Control.PRESET_CENTER
	)

	hit_marker.offset_left = -25
	hit_marker.offset_top = -25
	hit_marker.offset_right = 25
	hit_marker.offset_bottom = 25

	hit_marker.modulate.a = 0.0

	if canvas != null:

		canvas.add_child(
			hit_marker
		)

	hit_effect = Label.new()

	hit_effect.text = "◆"

	hit_effect.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	hit_effect.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	hit_effect.add_theme_font_size_override(
		"font_size",
		52
	)

	hit_effect.add_theme_color_override(
		"font_color",
		Color(
			1.0,
			0.65,
			0.05,
			0.9
		)
	)

	hit_effect.set_anchors_preset(
		Control.PRESET_CENTER
	)

	hit_effect.offset_left = -35
	hit_effect.offset_top = -35
	hit_effect.offset_right = 35
	hit_effect.offset_bottom = 35

	hit_effect.modulate.a = 0.0

	if canvas != null:

		canvas.add_child(
			hit_effect
		)


# =========================================================
# تحديث Crosshair
# =========================================================

func update_crosshair(speed_ratio: float):

	if crosshair == null:
		return

	var size = 28.0

	size += (
		speed_ratio *
		10.0
	)

	if shoot_cooldown > 0.0:

		size += 12.0

	crosshair.add_theme_font_size_override(
		"font_size",
		int(size)
	)


# =========================================================
# تأثير الضرر
# =========================================================

func create_damage_effect():

	damage_flash = ColorRect.new()

	damage_flash.name = "DamageFlash"

	damage_flash.color = Color(
		0.9,
		0.0,
		0.0,
		0.0
	)

	damage_flash.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	damage_flash.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	var canvas = get_node_or_null(
		"GameHUD"
	)

	if canvas != null:

		canvas.add_child(
			damage_flash
		)


# =========================================================
# Vignette
# =========================================================

func create_vignette():

	vignette = ColorRect.new()

	vignette.color = Color(
		0.0,
		0.0,
		0.0,
		0.12
	)

	vignette.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	vignette.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	var canvas = get_node_or_null(
		"GameHUD"
	)

	if canvas != null:

		canvas.add_child(
			vignette
		)


# =========================================================
# الصحة المنخفضة
# =========================================================

func update_health_effect(delta):

	if vignette == null:
		return

	if health <= 1:

		low_health_time += delta

		var pulse = (
			sin(
				low_health_time *
				5.0
			) *
			0.5
		) + 0.5

		vignette.color = Color(
			0.25,
			0.0,
			0.0,
			0.10 +
			pulse *
			0.14
		)

	else:

		vignette.color = Color(
			0.0,
			0.0,
			0.0,
			0.12
		)


# =========================================================
# الأشرطة
# =========================================================

func update_bars():

	if health_bar != null:

		var health_ratio = (
			float(health) /
			float(MAX_HEALTH)
		)

		health_bar.offset_right = (
			25.0 +
			180.0 *
			health_ratio
		)

	if ammo_bar != null:

		var ammo_ratio = (
			float(bollets_left) /
			float(MAX_BULLETS)
		)

		ammo_bar.offset_left = (
			-25.0 -
			180.0 *
			ammo_ratio
		)

		if ammo_ratio <= 0.2:

			ammo_bar.color = Color(
				1.0,
				0.08,
				0.03,
				1.0
			)

		else:

			ammo_bar.color = Color(
				0.85,
				0.75,
				0.08,
				1.0
			)


# =========================================================
# وميض الفوهة
# =========================================================

func create_muzzle_flash():

	muzzle_light = OmniLight3D.new()

	muzzle_light.name = "MuzzleFlash"

	muzzle_light.visible = false

	muzzle_light.light_color = Color(
		1.0,
		0.55,
		0.15
	)

	muzzle_light.light_energy = 4.0

	muzzle_light.omni_range = 2.5

	gun.add_child(
		muzzle_light
	)

	muzzle_light.position = Vector3(
		0.0,
		-0.05,
		-0.8
	)


# =========================================================
# HUD Update
# =========================================================

func update_hud():

	if ammo_label != null:

		ammo_label.text = (
			str(bollets_left) +
			"/" +
			str(MAX_BULLETS)
		)

	if health_label != null:

		health_label.text = (
			str(health) +
			"/" +
			str(MAX_HEALTH)
		)

	if kills_label != null:

		kills_label.text = (
			"KILLS  " +
			str(kills)
		)

	if score_label != null:

		score_label.text = (
			"SCORE  " +
			str(score)
		)

	if timer_label != null:

		var minutes = int(
			survival_time / 60.0
		)

		var seconds = int(
			survival_time
		) % 60

		timer_label.text = (
			"%02d:%02d" %
			[
				minutes,
				seconds
			]
		)

	var spawner = get_tree().current_scene.get_node_or_null(
		"ZombieSpawner"
	)

	if spawner != null:

		if spawner.has_method(
			"get_current_wave"
		):

			var current_wave = (
				spawner.get_current_wave()
			)

			if wave_label != null:

				wave_label.text = (
					"WAVE  " +
					str(current_wave)
				)


# =========================================================
# Zombie Warning
# =========================================================

func update_zombie_warning():

	var nearest_distance = 9999.0

	var scene = get_tree().current_scene

	if scene == null:
		return

	for child in scene.get_children():

		if child is CharacterBody3D:

			if child.name.to_lower().begins_with(
				"zombi"
			):

				var distance = (
					global_position.distance_to(
						child.global_position
					)
				)

				if distance < nearest_distance:

					nearest_distance = distance

	if nearest_distance < 8.0:

		warning_time += get_physics_process_delta_time()

		if warning_label != null:

			var pulse = (
				sin(
					warning_time *
					8.0
				) *
				0.5
			) + 0.5

			warning_label.modulate.a = (
				0.35 +
				pulse *
				0.65
			)

	else:

		if warning_label != null:

			warning_label.modulate.a = move_toward(
				warning_label.modulate.a,
				0.0,
				0.08
			)


# =========================================================
# Heartbeat
# =========================================================

func update_heartbeat(delta):

	if health > 1:

		if heartbeat_label != null:

			heartbeat_label.modulate.a = 0.0

		return

	heartbeat_timer -= delta

	if heartbeat_timer <= 0.0:

		heartbeat_timer = heartbeat_interval

		play_sound(
			heartbeat_sound,
			-5.0
		)

	if heartbeat_label != null:

		var pulse = (
			sin(
				hud_time *
				7.0
			) *
			0.5
		) + 0.5

		heartbeat_label.modulate.a = (
			0.35 +
			pulse *
			0.65
		)


# =========================================================
# تأثيرات عامة
# =========================================================

func update_effects(delta):

	if damage_flash != null:

		var current_alpha = (
			damage_flash.color.a
		)

		current_alpha = move_toward(
			current_alpha,
			0.0,
			2.5 * delta
		)

		damage_flash.color.a = current_alpha


# =========================================================
# Wave Announcement
# =========================================================

func show_wave_announcement(wave_number):

	if wave_announcement == null:
		return

	wave_announcement.text = (
		"WAVE " +
		str(wave_number)
	)

	wave_announcement.modulate.a = 1.0

	wave_announcement_timer = 2.5


# =========================================================
# الموت
# =========================================================

func player_died():

	if is_dead:
		return

	is_dead = true

	velocity = Vector3.ZERO

	is_reloading = false

	Input.set_mouse_mode(
		Input.MOUSE_MODE_VISIBLE
	)

	create_death_menu()


# =========================================================
# Death Menu
# =========================================================

func create_death_menu():

	var canvas = get_node_or_null(
		"DeathMenu"
	)

	if canvas != null:
		return

	var death_canvas = CanvasLayer.new()

	death_canvas.name = "DeathMenu"

	death_canvas.layer = 20

	add_child(
		death_canvas
	)

	var death_panel = ColorRect.new()

	death_panel.color = Color(
		0.0,
		0.0,
		0.0,
		0.88
	)

	death_panel.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	death_canvas.add_child(
		death_panel
	)

	var death_title = Label.new()

	death_title.text = "لقد مت"

	death_title.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	death_title.add_theme_font_size_override(
		"font_size",
		58
	)

	death_title.add_theme_color_override(
		"font_color",
		Color(
			1,
			0.08,
			0.08
		)
	)

	death_title.set_anchors_preset(
		Control.PRESET_CENTER
	)

	death_title.offset_left = -250
	death_title.offset_top = -230
	death_title.offset_right = 250
	death_title.offset_bottom = -150

	death_canvas.add_child(
		death_title
	)

	var stats = Label.new()

	var minutes = int(
		survival_time / 60.0
	)

	var seconds = int(
		survival_time
	) % 60

	var wave_number = 1

	var spawner = get_tree().current_scene.get_node_or_null(
		"ZombieSpawner"
	)

	if spawner != null:

		if spawner.has_method(
			"get_current_wave"
		):

			wave_number = (
				spawner.get_current_wave()
			)

	stats.text = (
		"KILLS     " +
		str(kills) +
		"\n\n" +
		"SCORE     " +
		str(score) +
		"\n\n" +
		"WAVE      " +
		str(wave_number) +
		"\n\n" +
		"TIME      " +
		"%02d:%02d" %
		[
			minutes,
			seconds
		]
	)

	stats.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	stats.add_theme_font_size_override(
		"font_size",
		22
	)

	stats.add_theme_color_override(
		"font_color",
		Color(
			0.82,
			0.82,
			0.82
		)
	)

	stats.set_anchors_preset(
		Control.PRESET_CENTER
	)

	stats.offset_left = -180
	stats.offset_top = -125
	stats.offset_right = 180
	stats.offset_bottom = 100

	death_canvas.add_child(
		stats
	)

	var restart_button = Button.new()

	restart_button.text = "إعادة اللعب"

	restart_button.add_theme_font_size_override(
		"font_size",
		24
	)

	restart_button.set_anchors_preset(
		Control.PRESET_CENTER
	)

	restart_button.offset_left = -140
	restart_button.offset_top = 120
	restart_button.offset_right = 140
	restart_button.offset_bottom = 195

	restart_button.pressed.connect(
		restart_game
	)

	death_canvas.add_child(
		restart_button
	)

	restart_button.grab_focus()


# =========================================================
# Restart
# =========================================================

func restart_game():

	print(
		"إعادة تشغيل اللعبة..."
	)

	Input.set_mouse_mode(
		Input.MOUSE_MODE_CAPTURED
	)

	get_tree().reload_current_scene()


# =========================================================
# تشغيل الصوت
# =========================================================

func play_sound(
	stream: AudioStream,
	volume_db: float
):

	if stream == null:
		return

	var player = AudioStreamPlayer.new()

	add_child(
		player
	)

	player.stream = stream

	player.volume_db = volume_db

	player.play()

	player.finished.connect(
		player.queue_free
	)


# =========================================================
# صوت المسدس
# =========================================================

func create_shoot_sound() -> AudioStreamWAV:

	var sample_rate = 44100
	var duration = 0.28

	var samples = int(
		sample_rate *
		duration
	)

	var data = PackedByteArray()

	data.resize(
		samples *
		2
	)

	for i in range(samples):

		var t = float(i) / sample_rate

		var bass_frequency = (
			75.0 -
			25.0 *
			t /
			duration
		)

		var bass = sin(
			TAU *
			bass_frequency *
			t
		)

		var bass_envelope = exp(
			-24.0 *
			t
		)

		var crack_frequency = (
			1800.0 +
			700.0 *
			t
		)

		var crack = sin(
			TAU *
			crack_frequency *
			t
		)

		var crack_envelope = exp(
			-55.0 *
			t
		)

		var noise = randf_range(
			-1.0,
			1.0
		)

		var noise_envelope = exp(
			-38.0 *
			t
		)

		var body = sin(
			TAU *
			320.0 *
			t
		)

		var body_envelope = exp(
			-18.0 *
			t
		)

		var value = 0.0

		value += (
			bass *
			bass_envelope *
			0.85
		)

		value += (
			crack *
			crack_envelope *
			0.35
		)

		value += (
			noise *
			noise_envelope *
			0.65
		)

		value += (
			body *
			body_envelope *
			0.25
		)

		var final_envelope = 1.0

		if t > 0.16:

			final_envelope = 1.0 - (
				(t - 0.16) /
				0.12
			)

		value *= final_envelope
		value *= 0.72

		var sample = int(
			clamp(
				value *
				32767.0,
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
# صوت التعمير
# =========================================================

func create_reload_sound() -> AudioStreamWAV:

	var sample_rate = 44100
	var duration = 0.55

	var samples = int(
		sample_rate *
		duration
	)

	var data = PackedByteArray()

	data.resize(
		samples *
		2
	)

	for i in range(samples):

		var t = float(i) / sample_rate

		var click1 = sin(
			TAU *
			650.0 *
			t
		)

		var click2 = sin(
			TAU *
			1100.0 *
			t
		)

		var click3 = sin(
			TAU *
			420.0 *
			t
		)

		var envelope = 0.0

		if t < 0.08:

			envelope = 1.0 - (
				t /
				0.08
			)

		elif t > 0.20 and t < 0.28:

			envelope = 1.0 - (
				(t - 0.20) /
				0.08
			)

		elif t > 0.38 and t < 0.50:

			envelope = 1.0 - (
				(t - 0.38) /
				0.12
			)

		var value = (
			click1 * 0.5 +
			click2 * 0.3 +
			click3 * 0.25
		)

		value *= envelope
		value *= 0.45

		var sample = int(
			clamp(
				value *
				32767.0,
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
# صوت الضرر
# =========================================================

func create_player_damage_sound() -> AudioStreamWAV:

	var sample_rate = 44100
	var duration = 0.18

	var samples = int(
		sample_rate *
		duration
	)

	var data = PackedByteArray()

	data.resize(
		samples *
		2
	)

	for i in range(samples):

		var t = float(i) / sample_rate

		var frequency = (
			180.0 -
			80.0 *
			t /
			duration
		)

		var envelope = (
			1.0 -
			t /
			duration
		)

		var value = sin(
			TAU *
			frequency *
			t
		)

		value *= envelope
		value *= 0.5

		var sample = int(
			clamp(
				value *
				32767.0,
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
# Heartbeat Sound
# =========================================================

func create_heartbeat_sound() -> AudioStreamWAV:

	var sample_rate = 44100
	var duration = 0.16

	var samples = int(
		sample_rate *
		duration
	)

	var data = PackedByteArray()

	data.resize(
		samples *
		2
	)

	for i in range(samples):

		var t = float(i) / sample_rate

		var frequency = 55.0

		var pulse = sin(
			TAU *
			frequency *
			t
		)

		var envelope = exp(
			-22.0 *
			t
		)

		var value = (
			pulse *
			envelope *
			0.7
		)

		var sample = int(
			clamp(
				value *
				32767.0,
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
# Kill Sound
# =========================================================

func create_kill_sound() -> AudioStreamWAV:

	var sample_rate = 44100
	var duration = 0.12

	var samples = int(
		sample_rate *
		duration
	)

	var data = PackedByteArray()

	data.resize(
		samples *
		2
	)

	for i in range(samples):

		var t = float(i) / sample_rate

		var frequency = (
			700.0 +
			900.0 *
			t /
			duration
		)

		var envelope = (
			1.0 -
			t /
			duration
		)

		var value = sin(
			TAU *
			frequency *
			t
		)

		value *= envelope
		value *= 0.28

		var sample = int(
			clamp(
				value *
				32767.0,
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
