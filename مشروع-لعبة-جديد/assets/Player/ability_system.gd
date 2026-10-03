extends Node

# =========================================================
# PLAYER
# =========================================================

var player = null

# =========================================================
# SPRINT ABILITY
# =========================================================

const SPRINT_DURATION = 6.0
const SPRINT_COOLDOWN = 18.0
const SPRINT_MULTIPLIER = 1.8

var sprint_active = false
var sprint_time_left = 0.0
var sprint_cooldown_left = 0.0

# =========================================================
# DOUBLE DAMAGE ABILITY
# =========================================================

const DOUBLE_DAMAGE_DURATION = 8.0
const DOUBLE_DAMAGE_COOLDOWN = 30.0
const DOUBLE_DAMAGE_MULTIPLIER = 2.0

var double_damage_active = false
var double_damage_time_left = 0.0
var double_damage_cooldown_left = 0.0

# =========================================================
# UI
# =========================================================

var ability_ui: CanvasLayer

var sprint_button: Button
var damage_button: Button

var sprint_bar: ProgressBar
var damage_bar: ProgressBar

var sprint_status: Label
var damage_status: Label


# =========================================================
# READY
# =========================================================

func _ready():

	player = get_parent()

	create_ui()


# =========================================================
# PROCESS
# =========================================================

func _process(delta):

	update_timers(delta)

	update_ui()


# =========================================================
# TIMER SYSTEM
# =========================================================

func update_timers(delta):

	# =====================================================
	# SPRINT ACTIVE
	# =====================================================

	if sprint_active:

		sprint_time_left -= delta

		if sprint_time_left <= 0.0:

			sprint_time_left = 0.0
			sprint_active = false
			sprint_cooldown_left = SPRINT_COOLDOWN


	# =====================================================
	# SPRINT COOLDOWN
	# =====================================================

	elif sprint_cooldown_left > 0.0:

		sprint_cooldown_left -= delta

		if sprint_cooldown_left <= 0.0:

			sprint_cooldown_left = 0.0


	# =====================================================
	# DOUBLE DAMAGE ACTIVE
	# =====================================================

	if double_damage_active:

		double_damage_time_left -= delta

		if double_damage_time_left <= 0.0:

			double_damage_time_left = 0.0
			double_damage_active = false
			double_damage_cooldown_left = DOUBLE_DAMAGE_COOLDOWN


	# =====================================================
	# DOUBLE DAMAGE COOLDOWN
	# =====================================================

	elif double_damage_cooldown_left > 0.0:

		double_damage_cooldown_left -= delta

		if double_damage_cooldown_left <= 0.0:

			double_damage_cooldown_left = 0.0


# =========================================================
# ACTIVATE SPRINT
# =========================================================

func activate_sprint():

	if sprint_active:
		return

	if sprint_cooldown_left > 0.0:
		return

	sprint_active = true
	sprint_time_left = SPRINT_DURATION

	ability_flash(
		Color(
			0.10,
			0.50,
			1.00,
			1.0
		)
	)


# =========================================================
# ACTIVATE DOUBLE DAMAGE
# =========================================================

func activate_double_damage():

	if double_damage_active:
		return

	if double_damage_cooldown_left > 0.0:
		return

	double_damage_active = true
	double_damage_time_left = DOUBLE_DAMAGE_DURATION

	ability_flash(
		Color(
			1.00,
			0.15,
			0.02,
			1.0
		)
	)


# =========================================================
# GET SPEED MULTIPLIER
# =========================================================

func get_speed_multiplier() -> float:

	if sprint_active:

		return SPRINT_MULTIPLIER

	return 1.0


# =========================================================
# GET DAMAGE MULTIPLIER
# =========================================================

func get_damage_multiplier() -> float:

	if double_damage_active:

		return DOUBLE_DAMAGE_MULTIPLIER

	return 1.0


# =========================================================
# INPUT
# =========================================================

func _unhandled_input(event):

	if event.is_action_pressed("ability_sprint"):

		activate_sprint()

	if event.is_action_pressed("ability_damage"):

		activate_double_damage()


# =========================================================
# CREATE UI
# =========================================================

func create_ui():

	ability_ui = CanvasLayer.new()

	ability_ui.layer = 20

	player.add_child(
		ability_ui
	)

	var container = HBoxContainer.new()

	container.set_anchors_preset(
		Control.PRESET_BOTTOM_LEFT
	)

	container.position = Vector2(
		30,
		-130
	)

	container.add_theme_constant_override(
		"separation",
		15
	)

	ability_ui.add_child(
		container
	)


	# =====================================================
	# SPRINT PANEL
	# =====================================================

	var sprint_panel = create_ability_panel(
		"🏃",
		"سرعة"
	)

	container.add_child(
		sprint_panel
	)

	sprint_button = sprint_panel.get_node(
		"Button"
	)

	sprint_bar = sprint_panel.get_node(
		"Bar"
	)

	sprint_status = sprint_panel.get_node(
		"Status"
	)

	sprint_button.pressed.connect(
		activate_sprint
	)


	# =====================================================
	# DAMAGE PANEL
	# =====================================================

	var damage_panel = create_ability_panel(
		"💥",
		"ضرر ×2"
	)

	container.add_child(
		damage_panel
	)

	damage_button = damage_panel.get_node(
		"Button"
	)

	damage_bar = damage_panel.get_node(
		"Bar"
	)

	damage_status = damage_panel.get_node(
		"Status"
	)

	damage_button.pressed.connect(
		activate_double_damage
	)


# =========================================================
# CREATE ABILITY PANEL
# =========================================================

func create_ability_panel(
	icon_text: String,
	name_text: String
) -> Panel:

	var panel = Panel.new()

	panel.custom_minimum_size = Vector2(
		145,
		100
	)

	var style = StyleBoxFlat.new()

	style.bg_color = Color(
		0.01,
		0.015,
		0.025,
		0.94
	)

	style.border_color = Color(
		0.35,
		0.35,
		0.40,
		1.0
	)

	style.set_border_width_all(2)

	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10

	panel.add_theme_stylebox_override(
		"panel",
		style
	)


	# =====================================================
	# BUTTON
	# =====================================================

	var button = Button.new()

	button.name = "Button"

	button.text = icon_text

	button.position = Vector2(
		8,
		7
	)

	button.size = Vector2(
		52,
		52
	)

	button.add_theme_font_size_override(
		"font_size",
		27
	)

	panel.add_child(
		button
	)


	# =====================================================
	# NAME
	# =====================================================

	var name_label = Label.new()

	name_label.name = "Name"

	name_label.text = name_text

	name_label.position = Vector2(
		62,
		8
	)

	name_label.size = Vector2(
		72,
		28
	)

	name_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	name_label.add_theme_font_size_override(
		"font_size",
		16
	)

	panel.add_child(
		name_label
	)


	# =====================================================
	# STATUS
	# =====================================================

	var status = Label.new()

	status.name = "Status"

	status.text = "جاهزة"

	status.position = Vector2(
		62,
		38
	)

	status.size = Vector2(
		72,
		25
	)

	status.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	status.add_theme_font_size_override(
		"font_size",
		13
	)

	panel.add_child(
		status
	)


	# =====================================================
	# PROGRESS BAR
	# =====================================================

	var bar = ProgressBar.new()

	bar.name = "Bar"

	bar.position = Vector2(
		10,
		78
	)

	bar.size = Vector2(
		125,
		12
	)

	bar.min_value = 0.0

	bar.max_value = 100.0

	bar.value = 100.0

	bar.show_percentage = false

	panel.add_child(
		bar
	)


	return panel


# =========================================================
# UPDATE UI
# =========================================================

func update_ui():

	# =====================================================
	# SPRINT
	# =====================================================

	if sprint_active:

		sprint_status.text = (
			str(
				ceil(sprint_time_left)
			) +
			" ث"
		)

		sprint_bar.value = (
			sprint_time_left /
			SPRINT_DURATION *
			100.0
		)

		sprint_button.disabled = true


	elif sprint_cooldown_left > 0.0:

		sprint_status.text = (
			str(
				ceil(sprint_cooldown_left)
			) +
			" ث"
		)

		sprint_bar.value = (
			1.0 -
			(
				sprint_cooldown_left /
				SPRINT_COOLDOWN
			)
		) * 100.0

		sprint_button.disabled = true


	else:

		sprint_status.text = "جاهزة"

		sprint_bar.value = 100.0

		sprint_button.disabled = false


	# =====================================================
	# DOUBLE DAMAGE
	# =====================================================

	if double_damage_active:

		damage_status.text = (
			str(
				ceil(double_damage_time_left)
			) +
			" ث"
		)

		damage_bar.value = (
			double_damage_time_left /
			DOUBLE_DAMAGE_DURATION *
			100.0
		)

		damage_button.disabled = true


	elif double_damage_cooldown_left > 0.0:

		damage_status.text = (
			str(
				ceil(double_damage_cooldown_left)
			) +
			" ث"
		)

		damage_bar.value = (
			1.0 -
			(
				double_damage_cooldown_left /
				DOUBLE_DAMAGE_COOLDOWN
			)
		) * 100.0

		damage_button.disabled = true


	else:

		damage_status.text = "جاهزة"

		damage_bar.value = 100.0

		damage_button.disabled = false


# =========================================================
# ACTIVATION FLASH
# =========================================================

func ability_flash(
	flash_color: Color
):

	var flash = ColorRect.new()

	flash.color = flash_color

	flash.set_anchors_preset(
		Control.PRESET_FULL_RECT
	)

	flash.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	flash.modulate.a = 0.0

	ability_ui.add_child(
		flash
	)

	var tween = create_tween()

	tween.tween_property(
		flash,
		"modulate:a",
		0.22,
		0.08
	)

	tween.tween_property(
		flash,
		"modulate:a",
		0.0,
		0.30
	)

	tween.finished.connect(
		flash.queue_free
	)
