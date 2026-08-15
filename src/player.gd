class_name Player extends CharacterBody3D


const SPEED := 5.0
const JUMP_VELOCITY := 4.5
const MOUSE_SENS := 0.003
const PITCH_LIMIT := 1.4
const INTERP_SPEED := 15.0


@export var network_position: Vector3
@export var network_rotation: Vector3

var interact_subject: Interactable = null

var _sample_rate: int = 48000
var _voice_playback: AudioStreamGeneratorPlayback

@onready var camera: Camera3D = %Camera3D
@onready var camera_ray: RayCast3D = %CameraRay
@onready var interact_prompt: Label = %InteractPrompt
@onready var voice_player: AudioStreamPlayer3D = %VoicePlayer


func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())


func _exit_tree() -> void:
	if is_multiplayer_authority():
		Steam.stopVoiceRecording()


func _ready() -> void:
	camera_ray.enabled = is_multiplayer_authority()
	_sample_rate = Steam.getVoiceOptimalSampleRate()
	(voice_player.stream as AudioStreamGenerator).mix_rate = _sample_rate
	
	if is_multiplayer_authority():
		camera.make_current()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		Steam.startVoiceRecording()
		print("[voice] authority=%s rate=%d recording started" % [name, _sample_rate])
	else:
		voice_player.play()
		_voice_playback = voice_player.get_stream_playback()
		print("[voice] playback ready for %s, playback=%s" % [name, _voice_playback])



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


func _physics_process(delta: float) -> void:
	if is_multiplayer_authority():
		_move(delta)
		network_position = global_position
		network_rotation = Vector3(camera.rotation.x, rotation.y, 0.0)
		_update_interact_subject()
		_capture_voice()
	else:
		global_position = global_position.lerp(network_position, delta * INTERP_SPEED)
		rotation.y = lerp_angle(rotation.y, network_rotation.y, delta * INTERP_SPEED)
		camera.rotation.x = lerp_angle(camera.rotation.x, network_rotation.x, delta * INTERP_SPEED)


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
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
		velocity.z = move_toward(velocity.z, 0.0, SPEED)

	move_and_slide()


func _capture_voice() -> void:
	var available: Dictionary = Steam.getAvailableVoice()
	if Engine.get_physics_frames() % 60 == 0:
		print("[voice] getAvailableVoice -> %s" % available)
	if available.get("result") != Steam.VOICE_RESULT_OK or available.get("size", 0) == 0:
		return
	var voice: Dictionary = Steam.getVoice()
	if voice.get("result") == Steam.VOICE_RESULT_OK and voice.get("size", 0) > 0:
		print("[voice] TX %d bytes" % voice["buffer"].size())
		_receive_voice.rpc(voice["buffer"])


@rpc("authority", "call_remote", "unreliable_ordered")
func _receive_voice(buffer: PackedByteArray) -> void:
	var decompressed: Dictionary = Steam.decompressVoice(buffer, _sample_rate)
	print("[voice] RX %d bytes from %s -> decompress keys=%s result=%s" % [buffer.size(), name, decompressed.keys(), decompressed.get("result", "?")])
	if decompressed.get("result") != Steam.VOICE_RESULT_OK:
		return
	var pcm: PackedByteArray = decompressed["uncompressed"]
	@warning_ignore("integer_division") var frames := pcm.size() / 2
	var free := _voice_playback.get_frames_available()
	print("[voice] PLAY pcm=%d frames=%d free=%d playing=%s" % [pcm.size(), frames, free, voice_player.playing])
	for i in mini(frames, free):
		var s := pcm.decode_s16(i * 2) / 32768.0
		_voice_playback.push_frame(Vector2(s, s))
