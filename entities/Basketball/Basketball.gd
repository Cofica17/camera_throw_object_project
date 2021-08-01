
extends RigidBody
class_name Basketball

var picked_up

var holder

var dir = Vector3.ZERO

var last_mouse_rel_pos : Vector2 = Vector2.ZERO
var current_mouse_rel_pos : Vector2 = Vector2.ZERO


func _ready():
	Events.connect("ball_weight_changed", self, "_on_weight_changed")


func _on_weight_changed(value) -> void:
	weight = value


func pick_up(camera):
	holder = camera

	if picked_up:
		leave()
	else:
		carry()


#func _process(delta):
#	if picked_up:
#		translate(Vector3)


func _input(event):
	if picked_up and event is InputEventMouseMotion:
		var mouse_pos = get_viewport().get_mouse_position()
		var rayOrigin = holder.project_ray_origin(mouse_pos)
		var rayEnd = holder.project_ray_normal(mouse_pos) * 2000
		var intersection = get_world().direct_space_state.intersect_ray(rayOrigin, rayEnd)
		if not intersection.empty() and intersection.has("position"):
			var pos = intersection.position
			transform.origin.x = pos.x
			transform.origin.z = pos.z
			var mouse_dir = event.relative.normalized()
			dir.x = mouse_dir.x
			dir.z = mouse_dir.y
			last_mouse_rel_pos = current_mouse_rel_pos
			current_mouse_rel_pos = event.relative

func carry():
	$CollisionShape.set_disabled(true)
	holder.carried_object = self
	self.set_mode(1)
	picked_up = true

func leave():
	$CollisionShape.set_disabled(false)
	holder.carried_object = null
	self.set_mode(0)
	picked_up = false


func throw(power):
	leave()
	
	var dir_x_speed = 0
	if not last_mouse_rel_pos.x == 0:
		dir_x_speed = abs(current_mouse_rel_pos.x / last_mouse_rel_pos.x)

	var dir_z_speed = 0
	if not last_mouse_rel_pos.y == 0:
		dir_z_speed = abs(current_mouse_rel_pos.y / last_mouse_rel_pos.y)
	
	apply_impulse(Vector3(), dir * Vector3(power * dir_x_speed, power, power * dir_z_speed))
