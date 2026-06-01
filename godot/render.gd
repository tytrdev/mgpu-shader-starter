extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var a := OS.get_cmdline_user_args()
	var res := 256
	var outfile := "frame.png"
	if a.size() > 0:
		res = int(a[0])
	if a.size() > 1:
		outfile = a[1]

	var vp := SubViewport.new()
	vp.size = Vector2i(res, res)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.transparent_bg = false
	root.add_child(vp)

	var rect := ColorRect.new()
	rect.size = Vector2(res, res)
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shader.gdshader")
	mat.set_shader_parameter("iResolution", Vector3(res, res, 1.0))
	mat.set_shader_parameter("iTime", 0.0)
	mat.set_shader_parameter("iTimeDelta", 0.0)
	mat.set_shader_parameter("iFrame", 0)
	mat.set_shader_parameter("iMouse", Vector4(0, 0, 0, 0))
	rect.material = mat
	vp.add_child(rect)

	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	img.save_png(outfile)
	quit()
