extends CharacterBody2D

signal OnUpdateHealth (health : int)
signal OnUpdateScore (score : int)

@export var move_speed : float = 100
@export var acceleration : float = 50
@export var braking : float = 20
@export var gravity : float = 500
@export var jump_force : float = 200
@export var health : int = 3

var move_input : float
var is_on_rope = false

@onready var Sprite : Sprite2D = $Sprite
@onready var anim : AnimationPlayer = $AnimationPlayer
@onready var audio : AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var tile_map: TileMapLayer = $"../TileMapLayer"

var take_damage_sfx : AudioStream = preload("res://Audio/take_damage.wav")
var coin_sfx : AudioStream = preload("res://Audio/coin.wav")

func _physics_process(delta):
	var detection_pos = global_position + Vector2(0, -16)
	var map_pos = tile_map.local_to_map(tile_map.to_local(detection_pos))
	var source_id = tile_map.get_cell_source_id(map_pos)
	var tile_data = tile_map.get_cell_tile_data(map_pos)
	
	if source_id != -1 and tile_data and tile_data.get_custom_data("Climbable"):
		is_on_rope = true
	else:
		is_on_rope = false

	move_input = Input.get_axis("move_left", "move_right")

	if is_on_rope:
		velocity.y = 0
		var climb_dir = Input.get_axis("jump", "move_down")
		if climb_dir != 0:
			velocity.y = climb_dir * move_speed
		
		velocity.x = move_input * (move_speed * 0.5)
	else:
		if not is_on_floor():
			velocity.y += gravity * delta
		
		if move_input != 0:
			velocity.x = lerp(velocity.x, move_input * move_speed, acceleration * delta)
		else:
			velocity.x = lerp(velocity.x, 0.0, braking * delta)
			
		if Input.is_action_pressed("jump") and is_on_floor():
			velocity.y = -jump_force
	
	move_and_slide()

func _process(delta):
	if velocity.x != 0:
		Sprite.flip_h = velocity.x > 0
	
	if global_position.y > 200:
		game_over()

	_manage_animation()

func _manage_animation():
	if is_on_rope:
		anim.play("idle")
	elif not is_on_floor():
		anim.play("jump")
	elif move_input != 0:
		anim.play("move")
	else:
		anim.play("idle")

func take_damage(amount : int):
	health -= amount
	OnUpdateHealth.emit(health)
	_damage_flash()
	if health <= 0:
		call_deferred("game_over")
	play_sound(take_damage_sfx)

func game_over():
	get_tree().change_scene_to_file("res://Scenes/menu.tscn")

func increase_score(amount : int):
	PlayerStats.score += amount
	OnUpdateScore.emit(PlayerStats.score)
	play_sound(coin_sfx)

func _damage_flash():
	Sprite.modulate = Color.RED
	await get_tree().create_timer(0.05).timeout
	Sprite.modulate = Color.WHITE

func play_sound(sound : AudioStream):
	audio.stream = sound
	audio.play()
