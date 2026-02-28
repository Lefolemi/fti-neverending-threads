extends Node

enum Rank { NONE, AMATEUR, NOVICE, INTERMEDIATE, EXPERT, MASTER, MAGISTRA };

const QUESTIONS_PER_SET = 30;
const STUDY_SESSION_COUNT = 15;

# Map your dictionary into an Array so we can access it via GVar.ui_color (int)
const COLOR_PALETTE = [
	Color("2b2b2b"), Color("121212"), Color("0f2027"), Color("1b4332"),
	Color("4a0404"), Color("311b3d"), Color("3e2723"), Color("8a3324"),
	Color("000033"), Color("33691e"), Color("36454F"), Color("1a0b2e")
]

# The ultimate dynamic color formatter
func get_dynamic_text_color(base_color: Color) -> Color:
	var bg_color = COLOR_PALETTE[0]
	if GVar.ui_color >= 0 and GVar.ui_color < COLOR_PALETTE.size():
		bg_color = COLOR_PALETTE[GVar.ui_color]

	# 1. HARMONIZE: Blend 20% of the UI theme into the raw semantic color
	var harmonized = base_color.lerp(bg_color, 0.2)
	
	# 2. CONTRAST: Ensure it's readable
	if GVar.invert_ui_color:
		# If the background is light, make the text darker
		return harmonized.darkened(0.5)
	else:
		# If the background is dark, make the text pop and glow
		return harmonized.lightened(0.3)
