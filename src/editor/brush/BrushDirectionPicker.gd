tool
extends Popup

signal direction_changed(direction)

export(Resource) var brush = preload("res://editor/brush/ActiveBrush.tres")

export(Color) var border_color: Color = Color.white
export(Color) var selection_color: Color = Color.red
export(float) var line_width: float = 2
export(float) var none_radius_percent: float = 0.5
export(float) var min_margin: float = 16
export(int) var point_count: int = 32
export(float) var wheel_radians_speed: float = 0.1

var direction: float = NAN
var center: Vector2
var radius: float
var inner_radius: float
var dragging = false

func _ready() -> void:
	update_size()

func _draw() -> void:
	draw_arc(center, inner_radius, 0, TAU, point_count, border_color, line_width)
	draw_arc(center, radius, 0, TAU, point_count, border_color, line_width)
	if is_nan(direction):
		draw_circle(center, inner_radius * none_radius_percent, selection_color)
	else:
		var segment_direction = inner_radius * Vector2.RIGHT.rotated(direction)
		var starting_point = center + segment_direction
		draw_line(starting_point, starting_point + segment_direction, selection_color, line_width)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		update_size()
		update()
	elif what == NOTIFICATION_POST_POPUP:
		direction = brush.direction
		update()
	elif what == NOTIFICATION_POPUP_HIDE:
		dragging = false

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == BUTTON_WHEEL_DOWN:
				if is_nan(direction):
					set_direction(0)
				else:
					set_direction(direction + wheel_radians_speed)
			elif event.button_index == BUTTON_WHEEL_UP:
				if is_nan(direction):
					set_direction(0)
				else:
					set_direction(direction - wheel_radians_speed)
			elif event.button_index == BUTTON_LEFT:
				set_direction_from_position(event.position)
		else:
			dragging = false
	elif event is InputEventMouseMotion and dragging:
		set_direction_from_position(event.position)
	elif event.is_action_pressed("ui_accept"):
		hide()

func set_direction_from_position(position: Vector2) -> void:
	var vec: Vector2 = position - center
	var distance = vec.length()
	if distance <= inner_radius:
		set_direction(NAN)
	elif distance <= radius:
		set_direction(vec.angle())
	dragging = true

func update_size() -> void:
	center = rect_size * 0.5
	radius = min(center.x, center.y) - min_margin
	inner_radius = radius * 0.5

func set_direction(value: float) -> void:
	direction = value
	brush.direction = value
	update()
	emit_signal("direction_changed", value)
