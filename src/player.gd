class_name Player extends CharacterBody3D

const SPEED := 5.0
const JUMP_VELOCITY := 4.5
const MOUSE_SENS := 0.003
const PITCH_LIMIT := 1.4
const INTERP_SPEED := 15.0
const SAMPLE_RATE: int = 44100

@export
var player_type: Enums.PlayerType = Enums.PlayerType.Hunter

@export_group("Internal Networking", "network_")
@export var network_position: Vector3
@export var network_rotation: Vector3

var interact_subject: Interactable = null

var _voice_playback: AudioStreamGeneratorPlayback

@onready var camera: Camera3D = %Camera3D
@onready var camera_ray: RayCast3D = %CameraRay
@onready var interact_prompt: Label = %InteractPrompt
@onready var voice_player: AudioStreamPlayer3D = %VoicePlayer
@onready var _base_character: BaseCharacter = %BaseCharacter
@onready var _player_name_label: Label3D = %PlayerName

@onready var tool = %CrossbowPlayer

var health: float = 100.0

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())

func _exit_tree() -> void:
	if is_multiplayer_authority():
		Steam.stopVoiceRecording()

func _ready() -> void:
	camera_ray.enabled = is_multiplayer_authority()
	(voice_player.stream as AudioStreamGenerator).mix_rate = SAMPLE_RATE
	
	if is_multiplayer_authority():
		camera.make_current()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		Steam.startVoiceRecording()
	else:
		voice_player.play()
		_voice_playback = voice_player.get_stream_playback()
		_player_name_label.text = "Player %s" % self.name
		_player_name_label.visible = true

func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENS)
		camera.rotation.x = clampf(
			camera.rotation.x - event.relative.y * MOUSE_SENS,
			-PITCH_LIMIT, PITCH_LIMIT
		)

	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		elif Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if event.is_action_pressed("interact") and interact_subject:
		interact_subject.try_interact()
	
	if event.is_action_pressed("shoot"):
		tool.use()
	
	if event.is_action_pressed("reload"):
		tool.reload()

func _physics_process(delta: float) -> void:
	if is_multiplayer_authority():
		_move(delta)
		network_position = global_position
		network_rotation = Vector3(camera.rotation.x, rotation.y, 0.0)
		_update_interact_subject()
	else:
		global_position = global_position.lerp(network_position, delta * INTERP_SPEED)
		rotation.y = lerp_angle(rotation.y, network_rotation.y, delta * INTERP_SPEED)
		camera.rotation.x = lerp_angle(camera.rotation.x, network_rotation.x, delta * INTERP_SPEED)

func _process(_delta: float) -> void:
	if is_multiplayer_authority() and NetworkManager.connected:
		_capture_voice()

func _update_interact_subject() -> void:
	var collider = camera_ray.get_collider()
	if collider is Interactable:
		interact_subject = collider
	else:
		interact_subject = null
	
	if interact_subject:
		interact_prompt.show()
		interact_prompt.text = "%s\nF" % [interact_subject.prompt]
	else:
		interact_prompt.hide()

func _move(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	var dir := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	if dir:
		velocity.x = dir.x * SPEED
		velocity.z = dir.z * SPEED
		_base_character.running = true
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
		velocity.z = move_toward(velocity.z, 0.0, SPEED)
		_base_character.running = false
	move_and_slide()

func _capture_voice() -> void:
	var available: Dictionary = Steam.getAvailableVoice()
	if available.get("result") != Steam.VOICE_RESULT_OK or available.get("size", 0) == 0:
		return
	var voice: Dictionary = Steam.getVoice()
	if voice.get("result") == Steam.VOICE_RESULT_OK and voice.get("size", 0) > 0:
		_receive_voice.rpc(voice["buffer"])

@rpc("any_peer", "call_local", "unreliable")
func hit(damage: float) -> void:
	if is_multiplayer_authority():
		health -= damage
	_base_character.hit_anim()

@rpc("authority", "call_remote", "unreliable", 2)
func _receive_voice(buffer: PackedByteArray) -> void:
	var decompressed: Dictionary = Steam.decompressVoice(buffer, SAMPLE_RATE)
	if decompressed.get("result") != Steam.VOICE_RESULT_OK and decompressed.get("size") == 0:
		return
	var frames_to_push: PackedVector2Array = PackedVector2Array()
	frames_to_push.resize(decompressed["size"] / 2)
	if !decompressed.has("uncompressed"):
		return
	var decompressed_buffer: PackedByteArray = decompressed["uncompressed"]
	
	for i in range(0, decompressed["size"], 2):
		var sample_int: int = decompressed_buffer.decode_s16(i)
		var amplitude: float = float(sample_int) / 32768.0
		@warning_ignore("integer_division") frames_to_push[i / 2] = Vector2(amplitude, amplitude)
	
	if _voice_playback.get_frames_available() >= frames_to_push.size():
		_voice_playback.push_buffer(frames_to_push)
	elif _voice_playback.get_frames_available() > 0:
		_voice_playback.push_buffer(frames_to_push.slice(0, _voice_playback.get_frames_available()))
