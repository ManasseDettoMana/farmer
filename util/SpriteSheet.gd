class_name SpriteSheet
extends RefCounted
## Builds SpriteFrames at runtime by slicing a sprite-sheet texture into AtlasTextures.
## Avoids hand-authoring .tres animation resources for every character/animal.

## Add one animation taken from a single horizontal row of a grid sheet.
static func add_row_anim(frames: SpriteFrames, tex: Texture2D, anim: String,
		frame_w: int, frame_h: int, row: int, count: int, fps: float, loop: bool = true) -> void:
	if not frames.has_animation(anim):
		frames.add_animation(anim)
	frames.set_animation_speed(anim, fps)
	frames.set_animation_loop(anim, loop)
	for i in range(count):
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(i * frame_w, row * frame_h, frame_w, frame_h)
		frames.add_frame(anim, at)

## Convenience: build a SpriteFrames from a flat horizontal strip (single row).
static func from_strip(tex: Texture2D, anim: String, frame_w: int, frame_h: int,
		count: int, fps: float, loop: bool = true) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	add_row_anim(frames, tex, anim, frame_w, frame_h, 0, count, fps, loop)
	return frames
