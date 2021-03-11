# Copyright (c) 2021 Gil Barbosa Reis.
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
extends Control

export(float) var speed: float = 1
export(float) var faster_factor: float = 5
export(float) var mouse_speed: float = 0.01
export(float) var zoom_speed: float = 0.01
export(Resource) var selection = preload("res://editor/selection/ActiveSelection.tres")

onready var viewport: Viewport = $ViewportContainer/Viewport
onready var camera: Camera = $ViewportContainer/Viewport/Camera
onready var height_slider = $HeightDragIndicator
onready var zoom_slider = $ZoomSlider
onready var camera_initial_transform: Transform = camera.transform
var dragging: bool = false
var current_zoom = 0


func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("visualizer_zoom_up"):
		var factor = (faster_factor if Input.is_action_pressed("visualizer_3d_faster") else 1.0) * zoom_speed
		zoom_by(factor)
	elif event.is_action_pressed("visualizer_zoom_down"):
		var factor = (faster_factor if Input.is_action_pressed("visualizer_3d_faster") else 1.0) * zoom_speed
		zoom_by(-factor)
	elif event is InputEventMouseButton and event.is_pressed() and event.button_index == BUTTON_MIDDLE:
		start_panning()
	elif event is InputEventMouseButton and not event.is_pressed():
		stop_panning()
	if dragging and event is InputEventMouseMotion:
		var factor = (faster_factor if Input.is_action_pressed("visualizer_3d_faster") else 1.0) * mouse_speed
		update_camera_with_pan(event.relative * factor)
	elif event.is_action_pressed("visualizer_reset"):
		reset_camera()
	else:
		viewport.unhandled_input(event)


func start_panning() -> void:
	dragging = true
	grab_focus()


func stop_panning() -> void:
	dragging = false


func zoom_by(factor: float) -> void:
	zoom_to(current_zoom + factor)


func zoom_to(zoom: float) -> void:
	zoom_slider.value = zoom
	current_zoom = clamp(zoom, 0, 1)
	set_camera_zoom_percent(current_zoom)


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		stop_panning()
	elif what == NOTIFICATION_FOCUS_ENTER:
		set_process(true)
	elif what == NOTIFICATION_FOCUS_EXIT:
		set_process(false)


func update_camera_with_pan(_pan: Vector2) -> void:
	assert(false, "Implement me!!!")


func set_camera_zoom_percent(_percent: float) -> void:
	assert(false, "Implement me!!!")


func reset_camera() -> void:
	zoom_to(0)
	camera.transform = camera_initial_transform
