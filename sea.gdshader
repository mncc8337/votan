shader_type spatial;

uniform sampler2D normal_map_texture : hint_normal;
uniform vec3 water_color : source_color = vec3(0.0625, 0.1992, 0.3594);
uniform vec2 wave_direction_1 = vec2(1.0, 1.0);
uniform vec2 wave_direction_2 = vec2(-1.0, 1.0);
uniform float time_scale_1 : hint_range(0.0, 1.5, 0.01);
uniform float time_scale_2 : hint_range(0.0, 1.5, 0.01);

void fragment() {
	vec3 normal_map = texture(normal_map_texture, UV + wave_direction_1 * TIME * time_scale_1).xyz;
	normal_map += texture(normal_map_texture, UV + wave_direction_2 * TIME * time_scale_2).xyz;
	ROUGHNESS = 0.00;
	METALLIC = 0.0;
	NORMAL_MAP = normal_map;
	ALBEDO = water_color;
	ALPHA = 0.7;
}