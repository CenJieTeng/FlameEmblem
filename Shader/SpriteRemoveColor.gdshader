shader_type canvas_item;

void vertex() {
	// Called for every vertex the material is visible on.
}

uniform vec4 color_to_remove : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float threshold : hint_range(0.0, 1.0) = 0.1;

void fragment() {
	 vec4 tex_color = texture(TEXTURE, UV);

	// 计算颜色差异
    float color_diff = distance(tex_color.rgb, color_to_remove.rgb);

    // 如果颜色接近要移除的颜色，设置为透明
    if (color_diff < threshold) {
        COLOR = vec4(0.0, 0.0, 0.0, 0.0);
    } else {
        COLOR = tex_color;
    }
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
