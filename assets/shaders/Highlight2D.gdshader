shader_type canvas_item;

uniform vec3 outline_color: source_color;
uniform float progress: hint_range(0.0, 1.0);


void vertex() {
	VERTEX *= 1.0 + 2.0 * progress;
}

void fragment() {
	vec2 uv = UV * (1.0 + 2.0 * progress) - progress;
	vec2 frame;
	COLOR = texture(TEXTURE, uv);

	if (COLOR.a < 1.0){
		COLOR.rgb = mix(outline_color, COLOR.rgb, COLOR.a);

		for (float r = -PI; r < PI; r += PI / 8.0) {
			frame = uv + vec2(sin(r), cos(r) * TEXTURE_PIXEL_SIZE.y / TEXTURE_PIXEL_SIZE.x) * vec2(progress);
			COLOR.a += texture(TEXTURE, frame).a;
		}
	}
}