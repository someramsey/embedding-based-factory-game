shader_type canvas_item;
render_mode world_vertex_coords;

uniform vec2 bounds_min;
uniform vec2 bounds_max;

uniform int border_line_count = 5;
uniform float border_line_width = 3.0;      
uniform float border_line_gap = 3.0;        
uniform float border_dash_length = 24.0;    
uniform float border_dash_gap = 16.0;       
uniform float border_inner_speed = 10.0;    
uniform float border_outer_speed = 50.0;    

uniform float spacing = 40.0;
uniform int major_every = 5;
uniform float dot_radius = 1.2;
uniform float major_dot_radius = 2.2;
uniform float line_width = 1.0;

uniform vec4 background_color : source_color;
uniform vec4 inner_border_color : source_color;
uniform vec4 outer_border_color : source_color;
uniform vec4 dot_color : source_color;
uniform vec4 major_dot_color : source_color;
uniform vec4 line_color : source_color;
uniform vec4 major_line_color : source_color;

uniform float vignette : hint_range(0.0, 1.0) = 0.35;
uniform float reveal_radius = 400.0;
uniform float cursor_line_boost = 1.0;

global uniform vec2 mouse_world_position;
varying vec2 world_position;

void vertex() {
    world_position = VERTEX;
}

float antialiased_coverage(float signed_distance, float world_per_pixel) {
    float edge_width = world_per_pixel;
    return clamp(0.5 - signed_distance / edge_width, 0.0, 1.0);
}

vec4 blend_over(vec4 backdrop, vec4 source, float coverage) {
    float source_alpha = clamp(source.a * coverage, 0.0, 1.0);
    vec3 blended_rgb = source.rgb * source_alpha + backdrop.rgb * (1.0 - source_alpha);
    float blended_alpha = source_alpha + backdrop.a * (1.0 - source_alpha);
    return vec4(blended_rgb, blended_alpha);
}

vec4 blend_border(vec4 backdrop, vec2 position, float world_per_pixel, float time) {
    vec2 distance_from_min = position - bounds_min;
    vec2 distance_from_max = bounds_max - position;
    float distance_to_vertical_edge = min(distance_from_min.x, distance_from_max.x);
    float distance_to_horizontal_edge = min(distance_from_min.y, distance_from_max.y);

    float depth = min(distance_to_vertical_edge, distance_to_horizontal_edge);
    float along_edge = distance_to_vertical_edge < distance_to_horizontal_edge ? position.y : position.x;

    float dash_period = border_dash_length + border_dash_gap;
    float line_pitch = border_line_width + border_line_gap;

    float best_coverage = 0.0;
    vec4 stripe_color;
	
    for (int i = 0; i < border_line_count; i++) {
        float line_center = float(i) * line_pitch + border_line_width * 0.5;
        float line_coverage = antialiased_coverage(abs(depth - line_center) - border_line_width * 0.5, world_per_pixel);

        float speed = mix(border_outer_speed, border_inner_speed, float(i) / float(border_line_count - 1));
        float phase = along_edge - time * speed;
        float position_in_period = mod(phase, dash_period);
        float dash_coverage = antialiased_coverage(abs(position_in_period - dash_period * 0.5) - border_dash_length * 0.5, world_per_pixel);

        float line_alpha_coverage = line_coverage * dash_coverage;
        if (line_alpha_coverage > best_coverage) {
            best_coverage = line_alpha_coverage;
            stripe_color = mix(outer_border_color, inner_border_color, float(i) / float(border_line_count - 1));			
        }
    }

    return blend_over(backdrop, stripe_color, best_coverage);
}

void fragment() {
    float world_per_pixel = fwidth(world_position.x);
    vec2 cell_index = round(world_position / spacing);
    vec2 offset_from_cell_center = world_position - cell_index * spacing;

    vec2 major_axis = vec2(
        float(abs(mod(cell_index.x, float(major_every))) < 0.5),
        float(abs(mod(cell_index.y, float(major_every))) < 0.5)
    );
    float is_major_intersection = major_axis.x * major_axis.y;

    float distance_to_center = length(offset_from_cell_center);
    float minor_dot_coverage = antialiased_coverage(distance_to_center - dot_radius * world_per_pixel, world_per_pixel) * (1.0 - is_major_intersection);
    float major_dot_coverage = antialiased_coverage(distance_to_center - major_dot_radius * world_per_pixel, world_per_pixel) * is_major_intersection;

    float half_line_width = line_width * world_per_pixel * 0.5;
    float vertical_line_coverage = antialiased_coverage(abs(offset_from_cell_center.x) - half_line_width, world_per_pixel);
    float horizontal_line_coverage = antialiased_coverage(abs(offset_from_cell_center.y) - half_line_width, world_per_pixel);
    float minor_line_coverage = max(vertical_line_coverage * (1.0 - major_axis.x), horizontal_line_coverage * (1.0 - major_axis.y));
    float major_line_coverage = max(vertical_line_coverage * major_axis.x, horizontal_line_coverage * major_axis.y);

    float cursor_proximity = 1.0 - smoothstep(0.0, reveal_radius, distance(world_position, mouse_world_position));
    float cursor_line_multiplier = 1.0 + cursor_line_boost * cursor_proximity;

	vec4 premultiplied_color = vec4(background_color.rgb * background_color.a, background_color.a);
    premultiplied_color = blend_over(premultiplied_color, line_color, minor_line_coverage * cursor_line_multiplier);
    premultiplied_color = blend_over(premultiplied_color, major_line_color, major_line_coverage * cursor_line_multiplier);
    premultiplied_color = blend_over(premultiplied_color, dot_color, minor_dot_coverage);
    premultiplied_color = blend_over(premultiplied_color, major_dot_color, major_dot_coverage);

    float vignette_falloff = 1.0 - vignette * smoothstep(0.3, 0.75, distance(SCREEN_UV, vec2(0.5)));
    premultiplied_color *= vignette_falloff;

    premultiplied_color = blend_border(premultiplied_color, world_position, world_per_pixel, TIME);

    vec3 output_rgb = premultiplied_color.rgb / max(premultiplied_color.a, 1e-4);
    COLOR = vec4(output_rgb, premultiplied_color.a);
}