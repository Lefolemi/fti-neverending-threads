extends TextureRect

const PALETTE = [
	Color("2b2b2b"), Color("121212"), Color("0f2027"), Color("1b4332"),
	Color("4a0404"), Color("311b3d"), Color("3e2723"), Color("8a3324"),
	Color("000033"), Color("33691e"), Color("36454F"), Color("1a0b2e")
]

func _process(_delta: float) -> void:
	if material is ShaderMaterial:
		var mat = material as ShaderMaterial
		
		# Translate GVar index to Color object
		var theme_color = PALETTE[0]
		if GVar.ui_color >= 0 and GVar.ui_color < PALETTE.size():
			theme_color = PALETTE[GVar.ui_color]
		
		# Feed the shader
		mat.set_shader_parameter("ui_color", theme_color)
		mat.set_shader_parameter("invert_mode", GVar.invert_ui_color)
