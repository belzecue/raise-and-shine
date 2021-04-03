# Copyright (c) 2021 Gil Barbosa Reis.
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
extends Viewport

export(Resource) var project = preload("res://editor/project/ActiveEditorProject.tres")
export(ShaderMaterial) var height_to_normal_material = preload("res://editor/normal/HeightToNormal_material.tres")

onready var height_map_rect = $HeightMapRect
onready var current_normal = $CurrentNormal
onready var is_gles3 = OS.get_current_video_driver() == OS.VIDEO_DRIVER_GLES3
var height_map_image = Image.new()
var height_map_texture = ImageTexture.new()


func _ready() -> void:
	get_texture().flags = Texture.FLAG_FILTER
	height_map_rect.texture = height_map_texture
	_on_height_texture_changed(project.height_texture)
	project.connect("height_texture_changed", self, "_on_height_texture_changed")
	project.connect("normal_texture_changed", self, "_on_normal_texture_changed")
	project.connect("operation_applied", self, "_on_operation_applied")
	project.connect("operation_ended", self, "_on_operation_ended")


func update_height_in_rect(rect: Rect2) -> void:
	height_map_rect.subrect = rect.grow(1).clip(Rect2(Vector2.ZERO, size))
	height_map_rect.update()
	redraw()


func _on_normal_texture_changed(texture: Texture) -> void:
	current_normal.texture = texture
	current_normal.visible = true
	current_normal.update()
	render_target_clear_mode = Viewport.CLEAR_MODE_ONLY_NEXT_FRAME
	redraw()
	yield(VisualServer, "frame_post_draw")
	current_normal.visible = false


func redraw() -> void:
	render_target_update_mode = Viewport.UPDATE_ONCE


func _on_height_texture_changed(texture: Texture, _empty_data: bool = false) -> void:
	size = texture.get_size()
	current_normal.rect_size = size
	height_map_rect.rect_size = size
	height_to_normal_material.set_shader_param("bump_scale", min(size.x, size.y))
	if is_gles3:
		var data = project.height_algorithm.pool_real_to_byte(project.height_data.height_array)
		height_map_image.create_from_data(size.x, size.y, false, Image.FORMAT_RF, data)
	else:
		project.height_data.fill_image(height_map_image)
	height_map_texture.create_from_image(height_map_image, 0)
	render_target_clear_mode = Viewport.CLEAR_MODE_ONLY_NEXT_FRAME
	update_height_in_rect(Rect2(Vector2.ZERO, size))


func _on_operation_applied(operation, height_data: HeightMapData) -> void:
	if is_gles3:
		var data = project.height_algorithm.pool_real_to_byte(height_data.height_array)
		height_map_image.create_from_data(size.x, size.y, false, Image.FORMAT_RF, data)
	else:
		height_data.fill_image(height_map_image)
	height_map_texture.set_data(height_map_image)
	update_height_in_rect(operation.cached_rect)


func _on_operation_ended(operation, height_data: HeightMapData) -> void:
	if is_gles3:
		yield(VisualServer, "frame_post_draw")
		take_snapshot()
	else:
		var changed_rect = operation.cached_rect.grow(1).clip(Rect2(Vector2.ZERO, size))
		project.height_algorithm.fill_normalmap(height_data.height_array, project.normal_image, changed_rect)
		project.normal_texture.create_from_image(project.normal_image, project.normal_texture.flags)
		_on_normal_texture_changed(project.normal_texture)


func take_snapshot() -> void:
	project.normal_image = get_texture().get_data()
	project.normal_image.convert(HeightMapData.NORMAL_IMAGE_FORMAT)
	project.normal_texture.create_from_image(project.normal_image, project.normal_texture.flags)
