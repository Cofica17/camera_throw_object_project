
extends RigidBody
class_name Basketball

var picked_up

var holder

var dir = Vector3.ZERO

var mouse_speed : Vector2 = Vector2.ZERO


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
			var mouse_dir = event.relative.rotated(deg2rad(-holder.get_parent().rotation_degrees.y)).normalized()
			dir.x = mouse_dir.x
			dir.z = mouse_dir.y
			mouse_speed = event.speed.rotated(deg2rad(-holder.get_parent().rotation_degrees.y))

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
	
	var dir_x_speed = abs(mouse_speed.x)/10
	var dir_z_speed = abs(mouse_speed.y)/10
	
	apply_impulse(Vector3(), dir * Vector3(power * dir_x_speed, power, power * dir_z_speed))
