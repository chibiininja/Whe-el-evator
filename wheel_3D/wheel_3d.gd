@tool class_name Wheel3D extends Node3D

#region Signals
signal new_dir_selected() ## emitted when a new direction is selected.
signal new_dir_chosen(payload:WheelPayload) ## emitted when a direction is chosen
signal rotation_started ## emitted when the gimbal begins to be rotated.
signal rotation_finished ## emitted when the gimbal is finished rotating.
signal puzzle_finished ## emitted when the puzzle is complete.
#endregion

#region Export Variables
@export_group("Animations")
## controls the animation of the rotation of the wheel.
enum TweenType { 
	TRANS_LINEAR, ## linear animation.
	TRANS_SINE, ## sine animation.
	TRANS_QUINT, ## quint animation.
	TRANS_QUART, ## quart animation.
	TRANS_QUAD, ## quad animation.
	TRANS_EXPO, ## expo animation.
	TRANS_ELASTIC, ## elastic animation.
	TRANS_CUBIC, ## cubic animation.
	TRANS_CIRC, ## circ animation.
	TRANS_BOUNCE, ## bounce animation.
	TRANS_BACK, ## back animation.
	TRANS_SPRING ## spring animation.
	}
@export var rotation_tween_type:TweenType = TweenType.TRANS_CIRC ## holds the value of the animation type enum.
@export_range(0,2,0.05) var rotation_anim_time= 0.3 ## controls how long the rotation animation will play for.
@export var scaling_tween_type:TweenType = TweenType.TRANS_CIRC ## holds the value of the animation type enum.
@export_range(0,2,0.05) var scaling_anim_time= 0.3 ## controls how long the rotation animation will play for.

@export_group("Meshes")
@export var slice_meshes:Array[ArrayMesh] = [
	preload("uid://chispifwbnu7w"),
	preload("uid://dod1g5vu1vd43"),
	preload("uid://dgflsbdl75acx"),
	preload("uid://b8f33gf3xo11k")
] ## an array of slice meshes. order is [slice1,slice2,slice3,slice4] (smallest to largest)

@export_group("Settings")
@export var randomize_slices: bool = true
@export var hide_covers_on_reset: bool = true
@export var base_numbers:Array[int] = [-2,-1,1,2] ## base score values for the slices
@export var slice_values:Array[int] = [1,2,3,4]: ## slice value multiplier
	set(value):
		slice_values = value
		if Engine.is_editor_hint():
			_update_slices_mesh(value)
@export var target_selections:int = 4 ## how many selections are allowed; default is 4.
@export var covers_covered:Array[bool] = [false, false, false, false]:
	set(value):
		covers_covered = value
		for x in covers.size():
			if value[x]:
				show_cover(x)
			else:
				hide_cover(x)

@export_group("Text")
@export var slice_text:Array[String] = ["UP","RIGHT","DOWN","LEFT"]:
	set(value):
		slice_text = value
		if Engine.is_editor_hint():
			_update_slice_text(value)
#endregion

#region Onready Variables
@onready var slices:Array[MeshInstance3D] = [%slice1,%slice2,%slice3,%slice4] ## our triangles of varying sizes.
@onready var covers:Array[MeshInstance3D] = [%cover_up,%cover_right,%cover_down,%cover_left] ## our covers to indicate that the selection has already been chosen.
@onready var selector:Node3D = %selector ## a reference to our selector node.
@onready var slice_gimbal:MeshInstance3D = %slice_gimbal ## a reference to our slice gimbal.
@onready var areas:Array[Interactable] = [%area_up, %area_right, %area_down, %area_left] ## our areas for interactions
@onready var labels:Array[MeshInstance3D] = [%text_up, %text_right, %text_down, %text_left]
#endregion

#region Internal Variables
var current_value_mappings:Array[int] = [0,-90,180,90] ## assigns values to directions; format is as follows: [UP,RIGHT,DOWN,LEFT]
enum WheelState {AWAITING_SELECTION,ROTATING,NO_INPUT} ## enum dictating current state of wheel.
var _state:WheelState = WheelState.AWAITING_SELECTION ## variable containing current state of wheel.
var num_selections:int = 0 ## how many selections have been chosen
var _current_value:WheelPayload ## a WheelPayload object containing the wheel's value
var current_direction:int = 0 ## where the selector currently is.
const DIRECTIONS:Array[int] = [0,-90,180,90] ## rotation value (in degrees) for the wheel directions. [UP,RIGHT,DOWN,LEFT]
#endregion

#region Built-In Functions
#called when the scene is loaded into the tree
func _ready()->void:
	reset() # all the setup is contained in reset
	rotation_finished.connect(end_check) # check if puzzle is completed when rotation is done
	for a:int in areas.size():
		areas[a].on_ray_entered.connect(func(): current_direction=DIRECTIONS[a]; process_direction_input(current_direction); selector.visible = true)
		areas[a].interacted.connect(func(): process_confirm_input(current_direction))
		areas[a].on_ray_exited.connect(func(): selector.visible = false)
#endregion

#region Custom Functions
## processes the input direction and moves the selector to that direction.
func process_direction_input(direction:int)->void:
	if _state != WheelState.AWAITING_SELECTION: return
	selector.rotation_degrees.z = direction #move our selector to the direction
	_current_value = get_current_wheel_value() #set the current wheel value to our slice and base values
	new_dir_selected.emit() # emit signal that we have moved the selector

## confirms that the current selection has been chosen
func process_confirm_input(direction:int)->void:
	if _state != WheelState.AWAITING_SELECTION: return
		
	for x:int in covers.size():  # show the covers, increase the num selections, emit the signal, rotate
		if int(round(covers[x].rotation_degrees.z)) == direction: 
			if covers_covered[x]: return 
			
			covers_covered[x] = true
			show_cover(x)
			num_selections += 1
			new_dir_chosen.emit(_current_value)
			rotate_slices()

## shows cover with tween
func show_cover(index: int)->void:
	var tween:Tween = create_tween()
	tween.set_trans(int(scaling_tween_type))
	tween.tween_property(covers[index], "scale", Vector3(1,1,1), scaling_anim_time)

func hide_cover(index:int)->void:
	var tween:Tween = create_tween()
	tween.set_trans(int(scaling_tween_type))
	tween.tween_property(covers[index], "scale", Vector3(0.2,0.2,1), scaling_anim_time)
	tween.finished.connect(func(): covers_covered[index] = false)

## rotates the slice gimbal -90 degrees
func rotate_slices()->void:
	if _state != WheelState.AWAITING_SELECTION: return
	
	_state = WheelState.ROTATING 
	current_value_mappings = _rotate_array(current_value_mappings) # -90 to each of our current value mappings
	_current_value = get_current_wheel_value() # make sure the wheel value is updated
	rotation_started.emit() 
	var tween:Tween = create_tween() # create our tween object we will use for the animation
	tween.set_trans(int(rotation_tween_type)) # sets our transition type to our enum
	tween.tween_property(%slice_gimbal, "rotation_degrees",%slice_gimbal.rotation_degrees-Vector3(0,0,90),rotation_anim_time) # rotate gimbal
	tween.finished.connect(func(): rotation_finished.emit()) # emit rotation finished when done anim

## this function resets the minigame.
func reset()->void:
	randomize() # ensures that godot will randomize the shuffle of the mappings
	selector.rotation_degrees.z = 0 # remove this if you don't want the selector to reset up every time
	slice_gimbal.rotation_degrees.z = 0
	num_selections = 0 
	_update_slices_mesh(slice_values)
	_update_slice_text(slice_text)
	if hide_covers_on_reset:
		for x in covers.size():
			hide_cover(x)
	else:
		for x in covers.size():
			if covers_covered[x]:
				show_cover(x)
			else:
				hide_cover(x)
	
	if randomize_slices:
		current_value_mappings.shuffle() # chooses a random order for our value mappings
	else:
		current_value_mappings = [0,-90,180,90]
	for x:int in DIRECTIONS.size(): # assigns the slice value to the direction of the corresponding slice
		for j:int in current_value_mappings.size():
			slices[j].rotation_degrees.z = current_value_mappings[j]  # sets the slice rotations to our value mappings
			#if DIRECTIONS[x] == current_value_mappings[j]:
				#slice_values[x] = x+1
	
	if randomize_slices:
		base_numbers.shuffle() # shuffles base numbers so random wheel segments = a random base number
	_current_value = get_current_wheel_value() 
	_state = WheelState.AWAITING_SELECTION 

## checks if the minigame is finished
func end_check()->void:
	if num_selections == target_selections:
		_state = WheelState.NO_INPUT
		puzzle_finished.emit()
		selector.visible = false
	else:
		_state = WheelState.AWAITING_SELECTION

## returns the wheel value
func get_current_wheel_value()->WheelPayload:
	var wp:WheelPayload = WheelPayload.new()
	for x:int in current_value_mappings.size():
		if current_direction == current_value_mappings[x]:
			wp.current_direction = current_direction
			wp.base_value = base_numbers[x]
			wp.slice_value = slice_values[x]
			wp.total_value = wp.base_value * wp.slice_value
	return wp
#endregion

#region helper functions
## -90 degrees to each value mapping for rotation; also adjusts base values so they stay the same
func _rotate_array(arr:Array)->Array:
	var a:Array = arr
	var base_number_map:Dictionary = {a[0]:base_numbers[0],a[1]:base_numbers[1],a[2]:base_numbers[2],a[3]:base_numbers[3]} # saves where our base numbers are so we can make sure they match up after rotating
	for x:int in a.size():
		a[x] -= 90 # add 90 degrees to each value mapping
		if int(a[x]) == -180: a[x] = 180  # wrap values back
		
		base_numbers[x] = base_number_map.get(a[x]) # makes sure our base numbers stay the same
	return a

func _update_slices_mesh(new_values:Array[int])->void: 
	for x:int in slices.size(): # this assumes you will have the same amount of covers as slices. idk why you wouldn't.
		#update our slices with the new mesh
		slices[x].mesh = slice_meshes[new_values[x]-1]

func _update_slice_text(new_values:Array[String])->void:
	for x:int in labels.size():
		var text_mesh = labels[x].mesh as TextMesh
		text_mesh.text = new_values[x]
#endregion

#region WheelPayload Class
## allows us to create wheel payload objects and assign values to the wheel.
class WheelPayload:
	var current_direction: int
	var base_value:int
	var slice_value:int
	var total_value:int
#endregion
