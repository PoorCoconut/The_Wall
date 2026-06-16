shader_type canvas_item;

uniform sampler2D noise_texture : repeat_enable, filter_nearest;
uniform vec2 scroll_speed = vec2(0.5, 0.0); 
uniform vec4 magic_color : source_color = vec4(0.0, 2.0, 3.0, 1.0); 

// NEW: Controls the zoom level of your noise so it matches your ColorRect!
uniform float noise_scale = 0.02; 

// NEW: A variable to pass the world position from the vertex to the fragment
varying vec2 world_pos;

void vertex() {
	// Calculate the actual position of the tile in the game world
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	// 1. Use world_pos instead of UV for the noise! 
	// Multiply by scale to get that nice 32x32 chunky look
	vec2 moving_uv = (world_pos * noise_scale) + (TIME * scroll_speed);
	
	// 2. Read the noise texture
	vec4 noise_pixel = texture(noise_texture, moving_uv);
	
	// 3. We STILL use the normal UV here because we want the exact shape of your white tile mask
	vec4 base_pixel = texture(TEXTURE, UV);
	
	COLOR = noise_pixel * magic_color;
	COLOR.a *= base_pixel.a; 
}