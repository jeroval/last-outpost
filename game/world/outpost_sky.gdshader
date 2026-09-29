shader_type sky;
render_mode disable_fog;

uniform sampler2D cloud_noise : repeat_enable, filter_linear_mipmap;
uniform float coverage : hint_range(0.0, 1.0) = 0.48;
uniform float storm_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec3 sun_direction = vec3(0.47, 0.72, -0.51);

// A bounded cloud layer sampled along the view ray. The two noise projections
// produce a 3D density field without requiring Forward+ fog or a 3D texture.
float cloud_density(vec3 p) {
	float height = (p.y - 80.0) / 45.0;
	float envelope = smoothstep(0.0, 0.18, height) * (1.0 - smoothstep(0.55, 1.0, height));
	vec2 wind = vec2(TIME * 0.0018, TIME * 0.0006);
	float shape = texture(cloud_noise, p.xz * 0.001 + wind).r;
	float detail = texture(cloud_noise, p.xy * 0.0021 + p.z * 0.0007 + wind * 1.3).r;
	return smoothstep(1.0 - coverage, 1.18 - coverage, shape * 0.8 + detail * 0.2) * envelope;
}

void sky() {
	vec3 direction = normalize(EYEDIR);
	float elevation = max(direction.y, 0.0);
	vec3 horizon = mix(vec3(0.77, 0.85, 0.81), vec3(0.42, 0.49, 0.51), storm_amount);
	vec3 zenith = mix(vec3(0.22, 0.46, 0.59), vec3(0.22, 0.30, 0.35), storm_amount);
	vec3 background = mix(horizon, zenith, pow(elevation, 0.55));
	float sun_dot = max(dot(direction, sun_direction), 0.0);
	background += vec3(1.0, 0.77, 0.44) * (pow(sun_dot, 32.0) * 0.16 + smoothstep(0.9992, 0.9997, sun_dot) * 0.9) * (1.0 - storm_amount * 0.9);
	COLOR = background;
	// Animated radiance maps use the cheap atmosphere; ambient light remains
	// stable and cloud integration is paid only for visible background pixels.
	if (!AT_CUBEMAP_PASS && direction.y > 0.015) {
		vec3 origin = vec3(POSITION.x, clamp(POSITION.y, 0.0, 60.0), POSITION.z);
		float near_distance = (80.0 - origin.y) / direction.y;
		float far_distance = min((125.0 - origin.y) / direction.y, 3500.0);
		float step_length = max(far_distance - near_distance, 0.0) / 20.0;
		// Spatial jitter breaks up visible marching slices, especially near
		// the horizon. It stays fixed in time to avoid sparkling clouds.
		float jitter = fract(sin(dot(SCREEN_UV, vec2(12345.67, 45678.91))) * 43758.5453);
		float transmission = 1.0;
		vec3 cloud_light = vec3(0.0);
		for (int i = 0; i < 20; i++) {
			vec3 p = origin + direction * (near_distance + (float(i) + jitter) * step_length);
			float density = cloud_density(p);
			if (density < 0.001) {
				continue;
			}
			float opacity = 1.0 - exp(-density * step_length * 0.16);
			float shadow = cloud_density(p + sun_direction * 12.0);
			float lighting = clamp(0.78 + (p.y - 80.0) * 0.006 - shadow * 0.40, 0.38, 1.0);
			vec3 cloud_color = mix(vec3(1.0, 0.96, 0.86), vec3(0.52, 0.58, 0.60), storm_amount) * lighting;
			cloud_light += transmission * opacity * cloud_color;
			transmission *= 1.0 - opacity;
			if (transmission < 0.015) {
				break;
			}
		}
		float horizon_fade = smoothstep(0.04, 0.24, direction.y);
		COLOR = mix(background, background * transmission + cloud_light, horizon_fade);
	}
}
