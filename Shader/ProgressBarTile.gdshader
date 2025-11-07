shader_type canvas_item;

// 明确指定纹理参数
uniform sampler2D albedo_texture : source_color, filter_nearest, repeat_enable;
uniform float tile_count = 10.0;
uniform float progress : hint_range(0.0, 1.0) = 0.7;
uniform vec4 empty_color : source_color = vec4(0.0, 0.0, 0.0, 0.3);

void fragment() {
	
	vec2 tiled_uv = vec2(fract(UV.x * tile_count), UV.y);
    COLOR = texture(albedo_texture, tiled_uv);
	
    if (UV.x > progress) {
        // 进度条空的部分
		COLOR = COLOR * 0.6;
    }
}