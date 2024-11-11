shader_type spatial;
render_mode blend_mix, cull_front, unshaded;

uniform float offset: hint_range(0.0, 1.0, 0.01) = 0.05;
uniform float scale: hint_range(1.0, 2.0, 0.1) = 1.1;
uniform vec3 color : source_color = vec3(0,0,1);

void vertex() {
	VERTEX *= scale;
	
	//this shifts the box ever so slightly to the camera, which makes it look better on the board
	//thanks to random internet guy for this, i dont wanna figure it out, it works
	vec3 world_position = vec4(MODEL_MATRIX * vec4(VERTEX,1)).xyz;
	vec3 dir2cam  = normalize(CAMERA_POSITION_WORLD - world_position);
	world_position += dir2cam * offset;
	VERTEX = vec4(inverse(MODEL_MATRIX) * vec4(world_position,1)).xyz;
}

void fragment(){
	ALBEDO = color;
}