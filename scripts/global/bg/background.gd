extends CanvasLayer

@onready var wallpaper: TextureRect = $Wallpaper

func _ready() -> void:
	# Ensure the material is unique so we don't leak settings across instances
	if wallpaper.material:
		wallpaper.material = wallpaper.material.duplicate()

# Updated Master Function: Velocity now handles both direction and speed
func apply_background_settings(wp_texture: Texture2D, tint_color: Color, opacity: float, scale: float, velocity: Vector2, warp: float) -> void:
	# 1. Texture Handling
	if wp_texture:
		wallpaper.texture = wp_texture
		wallpaper.show()
	else:
		wallpaper.hide()
	
	# 2. Shader Parameter Injection
	if wallpaper.material is ShaderMaterial:
		var mat = wallpaper.material as ShaderMaterial
		
		# Coloring & Alpha
		mat.set_shader_parameter("tint_color", tint_color)
		mat.set_shader_parameter("opacity", opacity)
		
		# Geometry & Motion
		mat.set_shader_parameter("scale", scale)
		mat.set_shader_parameter("velocity", velocity) # Vector2(0,0) = static, (50,0) = fast
		
		# Special Effects
		mat.set_shader_parameter("warp_strength", warp)

# Helper for the solid color layer behind the wallpaper
func set_bg_color(color: Color) -> void:
	RenderingServer.set_default_clear_color(color)
