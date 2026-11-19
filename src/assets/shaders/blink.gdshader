shader_type canvas_item;
// Flash de dégât : mélange la couleur du sprite vers flash_color.
// flash_modifier = 0 : sprite normal ; 1 : entièrement flash_color.

uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float flash_modifier : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	color.rgb = mix(color.rgb, flash_color.rgb, flash_modifier);
	COLOR = color;
}
