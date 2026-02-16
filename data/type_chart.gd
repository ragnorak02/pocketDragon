class_name TypeChart
extends RefCounted
## Static type effectiveness chart.
## Elements: fire, ice, lightning, earth, neutral

# Effectiveness: 2.0 = super effective, 0.5 = not very effective, 1.0 = neutral
static var chart: Dictionary = {
	"fire": {"fire": 0.5, "ice": 2.0, "lightning": 1.0, "earth": 0.5, "neutral": 1.0},
	"ice": {"fire": 0.5, "ice": 0.5, "lightning": 1.0, "earth": 2.0, "neutral": 1.0},
	"lightning": {"fire": 1.0, "ice": 1.0, "lightning": 0.5, "earth": 0.5, "neutral": 1.0},
	"earth": {"fire": 2.0, "ice": 0.5, "lightning": 2.0, "earth": 0.5, "neutral": 1.0},
	"neutral": {"fire": 1.0, "ice": 1.0, "lightning": 1.0, "earth": 1.0, "neutral": 1.0},
}

static func get_multiplier(atk_element: String, def_element: String) -> float:
	if chart.has(atk_element) and chart[atk_element].has(def_element):
		return chart[atk_element][def_element]
	return 1.0

static func get_effectiveness_text(multiplier: float) -> String:
	if multiplier >= 2.0:
		return "Super effective!"
	elif multiplier <= 0.5:
		return "Not very effective..."
	return ""

static func get_element_color(element: String) -> Color:
	match element:
		"fire": return Color(1.0, 0.3, 0.1)
		"ice": return Color(0.3, 0.7, 1.0)
		"lightning": return Color(1.0, 0.9, 0.2)
		"earth": return Color(0.6, 0.45, 0.2)
		"neutral": return Color(0.7, 0.7, 0.7)
	return Color.WHITE
