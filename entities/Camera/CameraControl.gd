extends Camera

# Freelook settings
export (float, 0.0, 1.0) var sensitivity = 0.5
export (float, 0.0, 0.999, 0.001) var smoothness = 0.5 setget set_smoothness
export (int, 0, 360) var yaw_limit = 360
export (int, 0, 360) var pitch_limit = 360

# Movement settings
export (float, 0.0, 1.0) var acceleration = 1.0
export (float, 0.0, 0.0, 1.0) var deceleration = 0.1
export var move_camera_speed = 3
export var local = true

export var throw_force := 100
export var basketball_weight := 20 setget set_ball_weight
export var zoom_step := 0.4

# Input Actions
export var rotate_left_action = ""
export var rotate_right_action = ""
export var rotate_up_action = ""
export var rotate_down_action = ""
export var forward_action = "ui_up"
export var backward_action = "ui_down"
export var left_action = "ui_left"
export var right_action = "ui_right"
export var up_action = "camera_pan_up"
export var down_action = "camera_pan_down"
export var trigger_action = ""

# Gui settings
export var use_gui = true
export var gui_action = "ui_cancel"

# Intern variables.
var _mouse_offset = Vector2()
var _rotation_offset = Vector2()
var _yaw = 0.0
var _pitch = 0.0
var _total_yaw = 0.0
var _total_pitch = 0.0

var _direction = Vector3(0.0, 0.0, 0.0)
var _speed = Vector3(0.0, 0.0, 0.0)
var _gui

var _triggered=false

const ROTATION_MULTIPLIER = 500

var mouse_mode = Input.MOUSE_MODE_VISIBLE
var _camera_drag_pos :Vector2 = Vector2.ZERO
var _previous_mouse_pos :Vector2 = Vector2.ZERO

var can_camera_move := false
var rotate_camera := false

onready var pickup_pos : Position3D = get_node("PickupPos")

var carried_object

var can_pickup:bool = false
var pickup_timer:Timer = Timer.new()

var rotate_pivot


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_viewport().warp_mouse(get_viewport().size/2)
	
	add_child(pickup_timer)
	pickup_timer.autostart = false
	pickup_timer.one_shot = true
	pickup_timer.connect("timeout", self, "_on_pickup_timer_timeout")


func set_ball_weight(value) -> void:
	basketball_weight = value
	Events.emit_signal("ball_weight_changed", value)


func _on_pickup_timer_timeout() -> void:
	can_pickup = true
	_check_for_picakble_object()


func _input(event):
	if len(trigger_action)!=0:
		if event.is_action_pressed(trigger_action):
			_triggered=true
		elif event.is_action_released(trigger_action):
			_triggered=false
	else:
		_triggered=true
	
	if Input.is_action_pressed("camera_rotate"):
		rotate_camera = true
		if event is InputEventMouseMotion:
			_mouse_offset = event.relative
	
	if Input.is_action_just_released("camera_rotate"):
		rotate_pivot = null
		rotate_camera = false
	
	if Input.is_action_pressed("camera_move"):
		can_camera_move = true
		if event is InputEventMouseMotion:
			var new_vec = Vector2(
				-event.relative.x * move_camera_speed * 0.01,
				-event.relative.y * move_camera_speed * 0.01
			).rotated(deg2rad(-rotation_degrees.y))
			
			transform.origin.x += new_vec.x
			transform.origin.z += new_vec.y
		
	if Input.is_action_just_released("camera_move"):
		can_camera_move = false
	
	if Input.is_action_pressed("pick_up"):
		_check_for_picakble_object()

	if Input.is_action_just_released("pick_up"):
		if carried_object:
			carried_object.call_deferred("throw",throw_force)
			can_pickup = false
			carried_object = null
	
	if event is InputEventMouseButton:
		var step = 0
		if event.button_index == BUTTON_WHEEL_UP:
			step = zoom_step
		elif event.button_index == BUTTON_WHEEL_DOWN:
			step = -zoom_step
		var camera_position = global_transform.origin
		var target_position = pickup_pos.get_global_transform().origin
		var zoom = camera_position.move_toward(target_position, step)
		global_transform.origin = zoom


func _process(delta):
	if _triggered:
		_update_views(delta)


func _update_views(delta):
	if rotate_camera:
		_update_rotation(delta)


func _check_for_picakble_object() -> void:
	if carried_object:
		return
	
	var mouse_pos = get_viewport().get_mouse_position()
	var rayOrigin = project_ray_origin(mouse_pos)
	var rayEnd = project_ray_normal(mouse_pos) * 2000
	var intersection = get_world().direct_space_state.intersect_ray(rayOrigin, rayEnd)
	
	if not intersection.empty():
		var pos = intersection.position
		if intersection.has("collider"):
			var obj = intersection.collider
			if obj.has_method("pick_up"):
				if not can_pickup:
					pickup_timer.start(1)
				else:
					obj.pick_up(self)


func _update_rotation(delta):
	var offset = Vector2();
	
	offset += _mouse_offset * sensitivity
	
	_mouse_offset = Vector2()

	_yaw = _yaw * smoothness + offset.x * (1.0 - smoothness)
	_pitch = _pitch * smoothness + offset.y * (1.0 - smoothness)

	if yaw_limit < 360:
		_yaw = clamp(_yaw, -yaw_limit - _total_yaw, yaw_limit - _total_yaw)
	if pitch_limit < 360:
		_pitch = clamp(_pitch, -pitch_limit - _total_pitch, pitch_limit - _total_pitch)

	_total_yaw += _yaw
	_total_pitch += _pitch

	#if privot:
	if not rotate_pivot:
		var mouse_pos = get_viewport().get_mouse_position()
		var rayOrigin = project_ray_origin(mouse_pos)
		var rayEnd = project_ray_normal(mouse_pos) * 2000
		var intersection = get_world().direct_space_state.intersect_ray(rayOrigin, rayEnd)
		if not intersection.empty() and intersection.has("position"):
			rotate_pivot = intersection.position
	
	if rotate_pivot:
		var global_origin = global_transform.origin
		get_parent().transform.origin = rotate_pivot
		global_transform.origin = global_origin
		get_parent().rotate_y(deg2rad(-_yaw))
		get_parent().rotate_object_local(Vector3(1,0,0), deg2rad(-_pitch))


func set_smoothness(value):
	smoothness = clamp(value, 0.001, 0.999)
