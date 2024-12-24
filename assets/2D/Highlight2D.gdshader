shader_type canvas_item;

uniform vec3 outline_color: source_color;
uniform float progress: hint_range(0.0, 1.0);

void vertex() {
	VERTEX *= 1.0 + 2.0 * progress;
}

void fragment() {
	vec2 uv = UV * (1.0 + 2.0 * progress) - progress;
	COLOR = texture(TEXTURE, uv);
	
	if (uv != clamp(uv, vec2(0), vec2(1)))
		COLOR.a = 0.0;
	
	if (COLOR.a < 1.0){
		COLOR.rgb = mix(outline_color, COLOR.rgb, COLOR.a);
		
		vec2 s = sign(.5 - UV);
		if(uv.y >= 0.0 && uv.y <= 1.0)
			COLOR.a += texture(TEXTURE, uv + vec2(s.x * progress, 0.0)).a;
		if(uv.x >= 0.0 && uv.x <= 1.0)
			COLOR.a += texture(TEXTURE, uv + vec2(0, s.y * progress)).a;
	}
	//inward outline variant:
	//float a = texture(TEXTURE, mix(UV, vec2(.5), -progress)).a;
	//if (a == 0.0){
		//COLOR.rgb = outline_color;
	//}

}