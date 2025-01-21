shader_type spatial;
render_mode blend_mix, cull_front, unshaded;

uniform float offset: hint_range(0.0, 1.0, 0.01) = 0.05;
uniform float size: hint_range(0.0, .5, 0.01) = .03;
uniform vec3 color : source_color = vec3(0,0,1);

void vertex() {
	//VERTEX.xz += size * sign(VERTEX.xz);
	//VERTEX.y += size * (sign(VERTEX.y)/2.0 + .5);
	VERTEX += size * normalize(VERTEX);

	//this shifts the box ever so slightly to the camera, which makes it look better on the board
	//thanks to random internet guy for this, i dont wanna figure it out, it works
	vec3 world_position = vec4(MODEL_MATRIX * vec4(VERTEX,1)).xyz;
	vec3 dir2cam  = normalize(CAMERA_POSITION_WORLD - world_position);
	world_position += dir2cam * size;
	VERTEX = vec4(inverse(MODEL_MATRIX) * vec4(world_position,1)).xyz;
}

void fragment(){
	ALBEDO = color;
}