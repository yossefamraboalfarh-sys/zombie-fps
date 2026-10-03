extends Control


# =========================================================
# متغيرات القائمة
# =========================================================

var title: Label
var subtitle: Label
var start_button: Button
var exit_button: Button

var music_player: AudioStreamPlayer


# =========================================================
# تشغيل القائمة
# =========================================================

func _ready():

	# إظهار الماوس
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# جعل القائمة تملأ الشاشة
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# إنشاء الصوت الخلفي
	create_background_sound()

	# إنشاء الخلفية
	create_background()

	# إنشاء العنوان
	create_title()

	# إنشاء الوصف
	create_subtitle()

	# إنشاء زر البدء
	create_start_button()

	# إنشاء زر الخروج
	create_exit_button()

	# تشغيل أنيميشن الدخول
	play_menu_animation()


# =========================================================
# الخلفية
# =========================================================

func create_background():

	var background = ColorRect.new()

	background.color = Color(
		0.008,
		0.008,
		0.012,
		1.0
	)

	background.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	add_child(background)

	# إضاءة حمراء خلف القائمة

	var glow = ColorRect.new()

	glow.color = Color(
		0.35,
		0.0,
		0.0,
		0.10
	)

	glow.set_anchors_preset(
		Control.PRESET_CENTER
	)

	glow.offset_left = -500
	glow.offset_top = -350
	glow.offset_right = 500
	glow.offset_bottom = 350

	add_child(glow)


# =========================================================
# العنوان
# =========================================================

func create_title():

	title = Label.new()

	title.text = "قتال زوم"

	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	title.add_theme_font_size_override(
		"font_size",
		72
	)

	title.add_theme_color_override(
		"font_color",
		Color(
			0.95,
			0.04,
			0.04,
			1.0
		)
	)

	title.set_anchors_preset(
		Control.PRESET_CENTER
	)

	title.offset_left = -350
	title.offset_top = -190
	title.offset_right = 350
	title.offset_bottom = -90

	add_child(title)


# =========================================================
# الوصف
# =========================================================

func create_subtitle():

	subtitle = Label.new()

	subtitle.text = "واجه الزومبي وابقَ على قيد الحياة"

	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	subtitle.add_theme_font_size_override(
		"font_size",
		20
	)

	subtitle.add_theme_color_override(
		"font_color",
		Color(
			0.65,
			0.65,
			0.65,
			1.0
		)
	)

	subtitle.set_anchors_preset(
		Control.PRESET_CENTER
	)

	subtitle.offset_left = -350
	subtitle.offset_top = -85
	subtitle.offset_right = 350
	subtitle.offset_bottom = -45

	add_child(subtitle)


# =========================================================
# زر البدء
# =========================================================

func create_start_button():

	start_button = Button.new()

	start_button.text = "▶  بدء"

	start_button.add_theme_font_size_override(
		"font_size",
		30
	)

	start_button.add_theme_color_override(
		"font_color",
		Color.WHITE
	)

	start_button.add_theme_stylebox_override(
		"normal",
		create_button_style(
			Color(0.55, 0.02, 0.02, 1.0),
			Color(0.75, 0.05, 0.05, 1.0)
		)
	)

	start_button.add_theme_stylebox_override(
		"hover",
		create_button_style(
			Color(0.75, 0.04, 0.04, 1.0),
			Color(1.0, 0.12, 0.12, 1.0)
		)
	)

	start_button.add_theme_stylebox_override(
		"pressed",
		create_button_style(
			Color(0.35, 0.01, 0.01, 1.0),
			Color(0.65, 0.03, 0.03, 1.0)
		)
	)

	start_button.set_anchors_preset(
		Control.PRESET_CENTER
	)

	start_button.offset_left = -190
	start_button.offset_top = -5
	start_button.offset_right = 190
	start_button.offset_bottom = 80

	add_child(start_button)

	# صوت عند الضغط
	start_button.pressed.connect(
		start_game
	)

	# صوت عند مرور الماوس
	start_button.mouse_entered.connect(
		button_hover_sound
	)


# =========================================================
# زر الخروج
# =========================================================

func create_exit_button():

	exit_button = Button.new()

	exit_button.text = "خروج"

	exit_button.add_theme_font_size_override(
		"font_size",
		25
	)

	exit_button.add_theme_color_override(
		"font_color",
		Color(
			0.85,
			0.85,
			0.85,
			1.0
		)
	)

	exit_button.add_theme_stylebox_override(
		"normal",
		create_button_style(
			Color(0.08, 0.08, 0.09, 1.0),
			Color(0.25, 0.25, 0.28, 1.0)
		)
	)

	exit_button.add_theme_stylebox_override(
		"hover",
		create_button_style(
			Color(0.16, 0.16, 0.18, 1.0),
			Color(0.5, 0.5, 0.55, 1.0)
		)
	)

	exit_button.add_theme_stylebox_override(
		"pressed",
		create_button_style(
			Color(0.04, 0.04, 0.05, 1.0),
			Color(0.2, 0.2, 0.22, 1.0)
		)
	)

	exit_button.set_anchors_preset(
		Control.PRESET_CENTER
	)

	exit_button.offset_left = -190
	exit_button.offset_top = 95
	exit_button.offset_right = 190
	exit_button.offset_bottom = 170

	add_child(exit_button)

	# صوت عند الضغط
	exit_button.pressed.connect(
		exit_game
	)

	# صوت عند مرور الماوس
	exit_button.mouse_entered.connect(
		button_hover_sound
	)


# =========================================================
# تصميم الأزرار
# =========================================================

func create_button_style(
	background_color: Color,
	border_color: Color
) -> StyleBoxFlat:

	var style = StyleBoxFlat.new()

	style.bg_color = background_color
	style.border_color = border_color

	style.set_border_width_all(2)

	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8

	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 12
	style.content_margin_bottom = 12

	return style


# =========================================================
# أنيميشن القائمة
# =========================================================

func play_menu_animation():

	# البداية شفافة

	title.modulate.a = 0.0
	subtitle.modulate.a = 0.0
	start_button.modulate.a = 0.0
	exit_button.modulate.a = 0.0

	# العنوان

	var title_start_y = title.position.y

	title.position.y -= 40

	var title_tween = create_tween()

	title_tween.set_parallel(true)

	title_tween.tween_property(
		title,
		"modulate:a",
		1.0,
		0.8
	)

	title_tween.tween_property(
		title,
		"position:y",
		title_start_y,
		0.8
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)

	# الوصف

	var subtitle_tween = create_tween()

	subtitle_tween.tween_interval(0.25)

	subtitle_tween.tween_property(
		subtitle,
		"modulate:a",
		1.0,
		0.6
	)

	# زر البدء

	var start_tween = create_tween()

	start_tween.tween_interval(0.45)

	start_tween.tween_property(
		start_button,
		"modulate:a",
		1.0,
		0.6
	)

	# زر الخروج

	var exit_tween = create_tween()

	exit_tween.tween_interval(0.65)

	exit_tween.tween_property(
		exit_button,
		"modulate:a",
		1.0,
		0.6
	)

	# صوت دخول القائمة

	await get_tree().create_timer(0.25).timeout

	play_sound(
		create_menu_start_sound()
	)


# =========================================================
# صوت المرور على الزر
# =========================================================

func button_hover_sound():

	play_sound(
		create_hover_sound()
	)


# =========================================================
# بدء اللعبة
# =========================================================

func start_game():

	play_sound(
		create_click_sound()
	)

	await get_tree().create_timer(0.12).timeout

	Input.set_mouse_mode(
		Input.MOUSE_MODE_CAPTURED
	)

	get_tree().change_scene_to_file(
		"res://main.tscn"
	)


# =========================================================
# الخروج
# =========================================================

func exit_game():

	play_sound(
		create_click_sound()
	)

	await get_tree().create_timer(0.12).timeout

	get_tree().quit()


# =========================================================
# تشغيل صوت
# =========================================================

func play_sound(stream: AudioStream):

	var player = AudioStreamPlayer.new()

	add_child(player)

	player.stream = stream

	player.play()

	player.finished.connect(
		player.queue_free
	)


# =========================================================
# صوت الضغط
# =========================================================

func create_click_sound() -> AudioStreamWAV:

	var sample_rate = 44100
	var duration = 0.16
	var samples = int(sample_rate * duration)

	var data = PackedByteArray()

	data.resize(samples * 2)

	for i in range(samples):

		var t = float(i) / sample_rate

		var frequency = 180.0 - (100.0 * t / duration)

		var envelope = 1.0 - (t / duration)

		var value = sin(
			TAU * frequency * t
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

	audio.format = AudioStreamWAV.FORMAT_16_BITS
	audio.mix_rate = sample_rate
	audio.stereo = false
	audio.data = data

	return audio


# =========================================================
# صوت المرور على الزر
# =========================================================

func create_hover_sound() -> AudioStreamWAV:

	var sample_rate = 44100
	var duration = 0.07
	var samples = int(sample_rate * duration)

	var data = PackedByteArray()

	data.resize(samples * 2)

	for i in range(samples):

		var t = float(i) / sample_rate

		var frequency = 900.0 + (300.0 * t / duration)

		var envelope = 1.0 - (t / duration)

		var value = sin(
			TAU * frequency * t
		)

		value *= envelope
		value *= 0.12

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

	audio.format = AudioStreamWAV.FORMAT_16_BITS
	audio.mix_rate = sample_rate
	audio.stereo = false
	audio.data = data

	return audio


# =========================================================
# صوت دخول القائمة
# =========================================================

func create_menu_start_sound() -> AudioStreamWAV:

	var sample_rate = 44100
	var duration = 0.8
	var samples = int(sample_rate * duration)

	var data = PackedByteArray()

	data.resize(samples * 2)

	for i in range(samples):

		var t = float(i) / sample_rate

		var frequency = 120.0 + (180.0 * t / duration)

		var envelope = 1.0 - (t / duration)

		envelope *= envelope

		var value = sin(
			TAU * frequency * t
		)

		value += sin(
			TAU * frequency * 0.5 * t
		) * 0.35

		value *= envelope
		value *= 0.20

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

	audio.format = AudioStreamWAV.FORMAT_16_BITS
	audio.mix_rate = sample_rate
	audio.stereo = false
	audio.data = data

	return audio


# =========================================================
# الموسيقى الخلفية
# =========================================================

func create_background_sound():

	music_player = AudioStreamPlayer.new()

	add_child(music_player)

	var sample_rate = 22050

	var duration = 8.0

	var samples = int(
		sample_rate * duration
	)

	var data = PackedByteArray()

	data.resize(samples * 2)

	for i in range(samples):

		var t = float(i) / sample_rate

		# نغمة منخفضة جدًا
		var bass = sin(
			TAU * 55.0 * t
		) * 0.22

		# نغمة ثانية أخف
		var dark = sin(
			TAU * 82.5 * t
		) * 0.10

		# اهتزاز خفيف
		var pulse = sin(
			TAU * 0.35 * t
		) * 0.08

		var value = (
			bass +
			dark +
			(pulse * bass)
		)

		# دخول وخروج ناعم للصوت
		var fade = 1.0

		if t < 1.0:
			fade = t

		if t > duration - 1.0:
			fade = duration - t

		value *= fade
		value *= 0.35

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

	audio.format = AudioStreamWAV.FORMAT_16_BITS

	audio.mix_rate = sample_rate

	audio.stereo = false

	audio.data = data

	# تكرار الموسيقى
	audio.loop_mode = AudioStreamWAV.LOOP_FORWARD

	audio.loop_begin = 0

	audio.loop_end = samples

	music_player.stream = audio

	# صوت منخفض عشان يفضل في الخلفية
	music_player.volume_db = -16.0

	music_player.play()
