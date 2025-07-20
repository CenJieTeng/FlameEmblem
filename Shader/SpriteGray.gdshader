shader_type canvas_item;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// 获取原始颜色
	vec4 color = texture(TEXTURE, UV);

	// 计算灰度值（标准亮度公式）
	float gray = dot(color.rgb, vec3(0.299, 0.587, 0.114));

	// 输出灰度颜色（保持 Alpha 通道）
	COLOR = vec4(vec3(gray), color.a);
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
