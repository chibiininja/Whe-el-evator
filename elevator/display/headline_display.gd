class_name HeadlineDisplay extends Node3D

@onready var color_rect: ColorRect = $SubViewport/ColorRect
@onready var label: Label = $SubViewport/ColorRect/Label

@export var scroll_speed: float = 300

const default_texts: Array[String] = [
	"This message is cool and thinks you are cool too :)",
	"have you had water today?",
	"BREAKING NEWS: Firefighter rescues cats and dogs from burning animal shelter",
	"do you remember?             the 21st night of september :dance:",
	"look behind you o.o",
	"Professional bird hunter kills two pidgeons with a rock",
	"Explorers discover new wheel-like structures on secluded island",
	"Scientists invent cure to cancer",
	"Free donuts in the lobby!",
	"i'm going to the bathroom, be right back",
	"egg bug reference :D",
	"how are the kids?",
	"1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16- ah shoot, i lost count",
	"working hard, or hardly working?",
	"it's 5 o'clock somewhere",
	"when is my shift over?",
	"booking a dentist appt takes over 20 calls!!!",
	"mom would be so proud",
	"just put the wheel in the bag",
	"the day starts when the coffee hits the brain",
	"shopping cart gets away in a wild goose chase!",
	"mall cop gets lost in the mall",
	"cow jumps over the mooooooooon",
	"jimmy's dumped goldfish found alive and HUGE in local pond, killing ecosystem",
]

const wheel_texts: Array[String] = [
	"how did i get here?",
	"who designed this thing?",
	"they're going to get so mad at me",
	"Local elevator man forced to learn new wheel mechanic",
	"not coerced to admire the wheel",
	"just gotta go up",
	"no stopping now",
	"why do all the floors look the same",
	"why can't i leave",
	"who are these people",
	"when did it get so crunchy in here",
	"can this day get any worse",
	"have i been here before?",
	"focus on the wheel"
]

const crash_texts: Array[String] = [
	"OH GOD GET ME OFF THIS THING",
	"HELP ME",
	"WHY WHY WHY WHY WHY WHY WHY WHY WHY WHY WHY WHY WHY WHY WHY",
	"HAVE MERCY ON ME",
	"WHAT DO YOU MEAN",
	"WHY ME",
	"HOLD ON",
	"THIS ISN'T REAL",
	"I'LL BE BACK",
	"HAHHAHHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHHAHAHAHAHAHAHHAHA",
]

var text_bag: Array[String]

enum GameState {default, malfunction, crash}
var game_state: GameState = GameState.default:
	set(value):
		game_state = value
		match value:
			GameState.default:
				scroll_speed = 300
			GameState.malfunction:
				scroll_speed = 600
			GameState.crash:
				scroll_speed = 1200
		text_bag.clear()
		_get_new_text()

func _ready() -> void:
	randomize()
	text_bag = default_texts.duplicate()
	text_bag.shuffle()
	label.text = text_bag.pop_front()

func _process(delta):
	label.position.x -= scroll_speed * delta
	if label.position.x < -label.size.x:
		_get_new_text()

# On the parent, e.g. ColorRect
# This gives this CanvasItem a "clipping mask" that only allows children to display within it's rect.
func _draw():
	RenderingServer.canvas_item_set_clip(color_rect.get_canvas_item(), true)

func _get_new_text():
	if text_bag.size() == 0:
		match game_state:
			GameState.default:
				text_bag = default_texts.duplicate()
			GameState.malfunction:
				text_bag = wheel_texts.duplicate()
			GameState.crash:
				text_bag = crash_texts.duplicate()
		text_bag.shuffle()
	label.text = text_bag.pop_front()
	label.reset_size()
	label.position.x = color_rect.size.x

func reset():
	game_state = GameState.default
