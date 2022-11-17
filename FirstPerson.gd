extends KinematicBody

var speed
var default_move_speed = 2
var sprint_move_speed = 5
var crouch_move_speed = 0.5
var crouch_speed = 20
var acceleration = 20
var gravity = 9.8
var jump = 4

var damage = 100

#for multi jumping
var jump_num = 0

#tracer blink ability
var blink_dist = 10
var blink_ready = true

var default_height = 1.5
var crouch_height = 0.5

var mouse_sensitivity = 0.2

var sprinting = false

var direction = Vector3()
var velocity = Vector3()
var fall = Vector3()

onready var head = $Head
onready var pcap = $CollisionShape
onready var bonker = $HeadBonker
onready var sprint_timer = $SprintTimer
onready var ability_timer = $AbilityTimer
onready var aimcast = $Head/Camera/AimCast
onready var muzzle = $Head/Camera/Gun/Muzzle

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg2rad(-event.relative.x * mouse_sensitivity))
		head.rotate_x(deg2rad(-event.relative.y * mouse_sensitivity))
		head.rotation.x = clamp(head.rotation.x, deg2rad(-90), deg2rad(90))

func _physics_process(delta):
	
	#fireing
	if Input.is_action_just_pressed("fire"):
		if aimcast.is_colliding():
			var bullet = get_world().direct_space_state
			var colliosion =  bullet.intersect_ray(muzzle.transform.origin, aimcast.get_collision_point())
			
			if colliosion:
				var target = colliosion.collider
				if target.is_in_group("Enemy"):
					print("hit enemy")
					target.health -= damage
	
	var head_boncked = false
	
	speed = default_move_speed
	
	direction = Vector3()
	
	if bonker.is_colliding():
		head_boncked = true
	
	if not is_on_floor():
		fall.y  -= gravity * delta
	else:
		jump_num = 0
		
	if  Input.is_action_just_pressed("jump") and is_on_floor():
		if jump_num == 0:
			fall.y = jump
			jump_num = 1
	
	if  Input.is_action_just_pressed("jump") and not is_on_floor():
		if jump_num == 1:
			fall.y = jump
			jump_num = 2
	
	if head_boncked:
		fall.y = -2
	
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	
	#crouching
	if Input.is_action_pressed("crouch"):
		pcap.shape.height -= crouch_speed * delta
		speed = crouch_move_speed
	elif not head_boncked:
		pcap.shape.height += crouch_speed * delta
	
	if head_boncked and pcap.shape.height != default_height:
		speed = crouch_move_speed
		
	pcap.shape.height = clamp(pcap.shape.height, crouch_height, default_height)
	
	
	#sprinting
	if Input.is_action_just_pressed("sprint") and not sprinting:
		sprinting = true
		sprint_timer.start()
	elif Input.is_action_just_pressed("sprint") and sprinting:
		sprinting = false
		
	if sprinting:
		speed = sprint_move_speed
	
	
	
	
	#moving
	if Input.is_action_pressed("move_forward"):
		
		direction -= transform.basis.z
		
		if Input.is_action_just_pressed("ability") and blink_ready:
			
			translate(Vector3(0, 0, -blink_dist))
			blink_ready = false
			ability_timer.start()
	
	elif Input.is_action_pressed("move_backward"):
		
		direction += transform.basis.z
		
		if Input.is_action_just_pressed("ability") and blink_ready:
			
			translate(Vector3(0, 0, blink_dist))
			blink_ready = false
			ability_timer.start()
	
	if Input.is_action_pressed("move_left"):
		
		direction -= transform.basis.x
		
		if Input.is_action_just_pressed("ability") and blink_ready:
			
			translate(Vector3(-blink_dist, 0, 0))
			blink_ready = false
			ability_timer.start()
	
	elif Input.is_action_pressed("move_right"):
		
		direction += transform.basis.x
		
		if Input.is_action_just_pressed("ability") and blink_ready:
			
			translate(Vector3(blink_dist, 0, 0))
			blink_ready = false
			ability_timer.start()
		
	direction = direction.normalized()
	velocity = velocity.linear_interpolate(direction * speed, acceleration * delta)
	
	velocity = move_and_slide(velocity, Vector3.UP)
	move_and_slide(fall, Vector3.UP, true)
	
	#ray casting
	#if Input.is_action_just_pressed("fire"):
	#	var direct_state = get_world().direct_space_state
	#	var collion = direct_state.intersect_ray(transform.origin, Vector3(0, 0, -20))
	#	
	#	if collion:
	#		print(collion.position)


func _on_SprintTimer_timeout():
	sprinting = false


func _on_AbilityTimer_timeout():
	blink_ready = true
