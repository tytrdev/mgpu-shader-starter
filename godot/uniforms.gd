extends ColorRect

var frame := 0

func _process(delta: float) -> void:
	var t := float(Time.get_ticks_msec()) / 1000.0
	var mp := get_local_mouse_position()
	var y := size.y - mp.y
	var down := 1.0 if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) else 0.0
	var m := material as ShaderMaterial
	m.set_shader_parameter("iResolution", Vector3(size.x, size.y, 1.0))
	m.set_shader_parameter("iTime", t)
	m.set_shader_parameter("iTimeDelta", delta)
	m.set_shader_parameter("iFrame", frame)
	m.set_shader_parameter("iMouse", Vector4(mp.x, y, mp.x * down, y * down))
	frame += 1
