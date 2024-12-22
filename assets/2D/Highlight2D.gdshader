shader_type canvas_item;

uniform vec3 outline_color: source_color;
uniform float progress: hint_range(0.0, 1.0);

void fragment() {
	if (COLOR.a == 0.0){
		COLOR.rgb = outline_color;
		COLOR.a = texture(TEXTURE, mix(UV, vec2(.5), progress)).a;
	}
	//inward outline variant:
	//float a = texture(TEXTURE, mix(UV, vec2(.5), -progress)).a;
	//if (a == 0.0){
		//COLOR.rgb = outline_color;
	//}

}