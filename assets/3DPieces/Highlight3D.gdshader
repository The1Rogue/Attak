shader_type spatial;
render_mode cull_front, unshaded;


uniform vec3 color : source_color = vec3(0,0,1);

void vertex() {
	//COLOR.b = mix(COLOR.b, 0, .5);
	VERTEX *= 1.1;
}

void fragment() {
	//if (COLOR.a == 0.0){
		ALBEDO = color;
		ALPHA = 1.0;
	//}
	// Called for every pixel the material is visible on.
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
