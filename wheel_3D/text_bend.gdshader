shader_type spatial;

uniform bool curve_down = true;

void vertex() {
	float vertical_shift = cos(VERTEX.x) - 1.0;
	float horizontal_shift = VERTEX.y;
	if (!curve_down){
		vertical_shift *= -1.0;
		horizontal_shift *= -1.0;
	}
	
	VERTEX.y += vertical_shift;
	VERTEX.x *= horizontal_shift + 1.0;
}

void fragment() {
	// Called for every pixel the material is visible on.
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
