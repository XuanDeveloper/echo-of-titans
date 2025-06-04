extends Area2D

@export var player: Node
@export var speed: float = 600.0
@export var friction: float = 1000.0
@export var bounce_factor: float = 0.7
@export var max_bounces: int = 3

var collect_delay: float = 0.1
var _collect_timer: float = 0.0
var can_be_collected: bool = false

var direction: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO
var is_moving: bool = true
var bounce_count: int = 0

@onready var wall_ray := $WallRay

func _ready():
	connect("area_entered", Callable(self, "_on_area_entered"))
	if not is_connected("body_entered", Callable(self, "_on_body_entered")):
		connect("body_entered", Callable(self, "_on_body_entered"))
	velocity = direction.normalized() * speed
	update_raycast()
	wall_ray.enabled = true
	collision_mask = 0xFFFF
	wall_ray.collision_mask = 0xFFFF
	_collect_timer = collect_delay
	can_be_collected = false

func update_raycast():
	if velocity.length() > 0:
		wall_ray.target_position = velocity.normalized() * 15

func _physics_process(delta):
	if not can_be_collected:
		_collect_timer -= delta
		if _collect_timer <= 0.0:
			can_be_collected = true

	if is_moving:
		for area in get_overlapping_areas():
			if area.is_in_group("red_gravity_field"):
				var redball = area.get_parent()
				var to_head = global_position - area.global_position
				var dist = to_head.length()
				var gravity_radius = area.get_node("CollisionShape2D").shape.radius
				var max_strength = redball.max_repel_strength
				if dist < gravity_radius:
					var force = (gravity_radius - dist) / gravity_radius
					var repel_strength = lerp(0.0, max_strength, force)
					var boss_pos = redball.boss_ref.global_position
					var to_boss = (boss_pos - global_position).normalized()
					var alignment = to_head.normalized().dot(to_boss)
					if alignment > 0.7:
						var lateral = Vector2(-to_boss.y, to_boss.x).normalized()
						var mix = 0.6
						var safe_dir = (to_head.normalized() * mix + lateral * (1.0 - mix)).normalized()
						velocity += safe_dir * repel_strength * delta
					else:
						velocity += to_head.normalized() * repel_strength * delta

			if area.is_in_group("blue_gravity_field"):
				var blueball = area.get_parent()
				if "max_attract_strength" in blueball:
					var max_strength = blueball.max_attract_strength
					var boss_pos = blueball.boss_ref.global_position
					var dist = (area.global_position - global_position).length()
					var gravity_radius = area.get_node("CollisionShape2D").shape.radius
					if dist < gravity_radius:
						var force = (gravity_radius - dist) / gravity_radius
						var attract_strength = lerp(0.0, max_strength, force)
						var away_from_boss = (global_position - boss_pos).normalized()
						velocity += away_from_boss * attract_strength * delta

		update_raycast()
		wall_ray.force_raycast_update()

		if wall_ray.is_colliding():
			handle_wall_collision(wall_ray.get_collision_normal())

		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		var motion = velocity * delta
		var buffer: float = 20.0
		if $CollisionShape2D.shape is CircleShape2D:
			buffer = max(20.0, $CollisionShape2D.shape.radius)
		var ray_length: float = motion.length() + buffer
		if motion.length() > 0:
			wall_ray.target_position = motion.normalized() * ray_length
			wall_ray.force_raycast_update()
			if wall_ray.is_colliding():
				var collision_point = wall_ray.get_collision_point()
				var dist_to_collision = collision_point.distance_to(global_position)
				if dist_to_collision <= ray_length:
					var move_vec = collision_point - global_position
					position += move_vec.normalized() * max(0, dist_to_collision - 1)
					handle_wall_collision(wall_ray.get_collision_normal())
					return
		position += motion

		if velocity.length() < 10:
			is_moving = false
			velocity = Vector2.ZERO

	else:
		if can_be_collected:
			for body in get_overlapping_bodies():
				if body.is_in_group("player"):
					if player and player.has_method("recover_projectile"):
						player.recover_projectile()
					queue_free()
					return

func _on_area_entered(area):
	if area.is_in_group("boss_shield"):
		if area.has_method("hit"):
			area.hit()
		var normal = (global_position - area.global_position).normalized()
		handle_wall_collision(normal)
		return

func handle_wall_collision(normal: Vector2):
	bounce_count += 1
	velocity = velocity.bounce(normal) * bounce_factor
	position += normal * 1
	if bounce_count >= max_bounces:
		is_moving = false
		velocity = Vector2.ZERO
		return
	if velocity.length() < 50:
		is_moving = false
		velocity = Vector2.ZERO

func _on_body_entered(body):
	if body.name == "wall" or "Wall" in body.name or body is TileMap or "TileMap" in body.name:
		if wall_ray.is_colliding():
			handle_wall_collision(wall_ray.get_collision_normal())
		else:
			var approximated_normal = (global_position - body.global_position).normalized()
			handle_wall_collision(approximated_normal)
		return
	if body.is_in_group("player") and is_moving:
		return
