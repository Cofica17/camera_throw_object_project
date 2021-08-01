# Licensed under the MIT License.
# Copyright (c) 2018-2020 Jaccomo Lorenz (Maujoe)

extends Control

# Constant Gui Settings
#*******************************************************************************
const GUI_POS = Vector2(10, 10)
const GUI_SIZE = Vector2(200, 0)
const DRAGGABLE = true

const CUSTOM_BACKGROUND = false
const BACKGROUND_COLOR = Color(0.15, 0.17, 0.23, 0.75) 

const MAX_SPEED = 50
const MOVE_SPEED = 10
const MAX_THROW_POWER = 500
const MAX_BALL_WEIGHT = 100
#*******************************************************************************

var camera
var shortcut
var node_list
var privot
var panel

var mouse_over = false
var mouse_pressed = false

func _init(camera, shortcut):
	self.camera = camera
	self.shortcut = shortcut

func _ready():
	if camera.enabled:
		set_process_input(true)
		
		# Create Gui
		panel = PanelContainer.new()
		panel.set_begin(GUI_POS)
		panel.set_custom_minimum_size(GUI_SIZE)
		
		if CUSTOM_BACKGROUND:
			var style = StyleBoxFlat.new()
			style.set_bg_color(BACKGROUND_COLOR)
			style.set_expand_margin_all(5)
			panel.add_stylebox_override("panel", style)
		
		var container = VBoxContainer.new()

		var lbl_sensitivity = Label.new()
		lbl_sensitivity.set_text("Camera rotate Sensitivity")

		var sensitivity = HScrollBar.new()
		sensitivity.set_max(1)
		sensitivity.set_value(camera.sensitivity)
		sensitivity.connect("value_changed",self,"_on_hsb_sensitivity_value_changed")

		var lbl_smoothless = Label.new()
		lbl_smoothless.set_text("Smoothness")

		var smoothness = HScrollBar.new()
		smoothness.set_max(0.999)
		smoothness.set_min(0.5)
		smoothness.set_value(camera.smoothness)
		smoothness.connect("value_changed",self,"_on_hsb_smoothness_value_changed")

		var lbl_speed = Label.new()
		lbl_speed.set_text("Pan Camera sensitivity")

		var speed = HScrollBar.new()
		speed.set_max(MAX_SPEED)
		speed.set_value(camera.pan_camera_speed.x)
		speed.connect("value_changed",self,"_on_hsb_speed_value_changed")
		
		var lbl_move_speed = Label.new()
		lbl_move_speed.set_text("Move Camera Sensitivity")
		
		var move_speed = HScrollBar.new()
		move_speed.set_max(MOVE_SPEED)
		move_speed.set_value(camera.move_camera_speed)
		move_speed.connect("value_changed",self,"_on_hsb_move_speed_value_changed")
		
		var lbl_acceleration = Label.new()
		lbl_acceleration.set_text("Pan Camera Acceleration")
		
		var acceleration = HScrollBar.new()
		acceleration.set_max(1.0)
		acceleration.set_value(camera.acceleration)
		acceleration.connect("value_changed", self, "_in_hsb_acceleration_value_changed")
		
		var lbl_deceleration = Label.new()
		lbl_deceleration.set_text("Pan Camera Deceleration")
		
		var deceleration = HScrollBar.new()
		deceleration.set_max(1.0)
		deceleration.set_value(camera.deceleration)
		deceleration.connect("value_changed", self, "_in_hsb_deceleration_value_changed")
		
		var lbl_throw_force = Label.new()
		lbl_throw_force.set_text("Throw Force")
		
		var throw_force = HScrollBar.new()
		throw_force.set_max(MAX_THROW_POWER)
		throw_force.set_value(camera.throw_force)
		throw_force.connect("value_changed", self, "_in_hsb_throw_force_value_changed")
		
		var lbl_ball_weight = Label.new()
		lbl_ball_weight.set_text("Basketball Weight")
		
		var ball_weight = HScrollBar.new()
		ball_weight.set_max(MAX_BALL_WEIGHT)
		ball_weight.set_value(camera.basketball_weight)
		ball_weight.connect("value_changed", self, "_in_hsb_ball_weight_value_changed")

		add_child(panel)
		panel.add_child(container)
		container.add_child(lbl_sensitivity)
		container.add_child(sensitivity)
		container.add_child(lbl_smoothless)
		container.add_child(smoothness)
		container.add_child(lbl_move_speed)
		container.add_child(move_speed)
		container.add_child(lbl_speed)
		container.add_child(speed)
		container.add_child(lbl_acceleration)
		container.add_child(acceleration)
		container.add_child(lbl_deceleration)
		container.add_child(deceleration)
		container.add_child(lbl_throw_force)
		container.add_child(throw_force)
		container.add_child(lbl_ball_weight)
		container.add_child(ball_weight)
		
		if DRAGGABLE:
			panel.connect("mouse_entered", self, "_panel_entered")
			panel.connect("mouse_exited", self, "_panel_exited")
			container.connect("mouse_entered", self, "_panel_entered")
			container.connect("mouse_exited", self, "_panel_exited")
		
		self.hide()
	else:
		set_process_input(false)

func _input(event):
	if event.is_action_pressed(shortcut):
		if camera.enabled:
			camera.enabled = false
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			self.show()
		else:
			camera.enabled = true
			self.hide()
			
	if DRAGGABLE:
		if event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
			mouse_pressed = event.pressed
			
		elif event is InputEventMouseMotion and mouse_over and mouse_pressed:
			panel.set_begin(panel.get_begin() + event.relative)

func _update_privots(privot):
	privot.clear()
	privot.add_item("None")
	node_list = _get_spatials_recusiv(get_tree().get_root(), [get_name(), camera.get_name()])

	var size = node_list.size()
	for i in range(0, size):
		var node = node_list[i]
		privot.add_item(node.get_name())
		if node == camera.privot:
			privot.select(i+1)

	if not camera.privot:
		privot.select(0)


func _get_spatials_recusiv(node, exceptions=[]):
	var list = []
	for child in node.get_children():
		if not child.get_name() in exceptions:
			if child is Spatial:
				list.append(child)
			if not child.get_children().empty():
				for subchild in _get_spatials_recusiv(child, exceptions):
					list.append(subchild)
	return list

func _panel_entered():
	mouse_over = true

func _panel_exited():
	mouse_over = false

func _on_opt_mouse_item_selected(id):
	camera.mouse_mode = id

func _on_btn_freelook_toggled(pressed):
	camera.freelook = pressed

func _on_hsb_sensitivity_value_changed(value):
	camera.sensitivity = value

func _on_hsb_smoothness_value_changed(value):
	camera.smoothness = value

func _on_hsb_speed_value_changed(value):
	camera.pan_camera_speed.x = value
	camera.pan_camera_speed.y = value
	camera.pan_camera_speed.z = value

func _on_hsb_move_speed_value_changed(value):
	camera.move_camera_speed = value

func _in_hsb_acceleration_value_changed(value):
	camera.acceleration = value
	
func _in_hsb_deceleration_value_changed(value):
	camera.deceleration = value

func _in_hsb_throw_force_value_changed(value):
	camera.throw_force = value 

func _in_hsb_ball_weight_value_changed(value):
	Events.emit_signal("ball_weight_changed", value)
