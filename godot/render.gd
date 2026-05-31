extends SceneTree

var vp: SubViewport
var frames := 0
var res := 256
var outfile := "frame.png"

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		res = int(a[0])
	if a.size() > 1:
		outfile = a[1]
	vp = SubViewport.new()
	vp.size = Vector2i(res, res)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
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

func _process(_delta: float) -> bool:
	frames += 1
	if frames < 3:
		return false
	var img := vp.get_texture().get_image()
	img.save_png(outfile)
	quit()
	return true
