#version 460 core
#include <flutter/runtime_effect.glsl>

precision highp float;

// Animated deep-space nebula used as the app-wide background.
uniform vec2 uSize;
uniform float uTime;
uniform vec2 uOffset; // parallax offset driven by scroll / tilt
uniform float uIntensity; // 0..1 nebula brightness

out vec4 fragColor;

float hash(vec2 p) {
  p = fract(p * vec2(123.34, 456.21));
  p += dot(p, p + 45.32);
  return fract(p.x * p.y);
}

float noise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  vec2 u = f * f * (3.0 - 2.0 * f);
  return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
             mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
  float v = 0.0;
  float a = 0.5;
  mat2 m = mat2(1.6, 1.2, -1.2, 1.6);
  for (int i = 0; i < 4; i++) {
    v += a * noise(p);
    p = m * p;
    a *= 0.5;
  }
  return v;
}

float stars(vec2 uv, float scale, float t, float density) {
  vec2 g = uv * scale;
  vec2 id = floor(g);
  vec2 f = fract(g) - 0.5;
  float h = hash(id);
  if (h < density) {
    return 0.0;
  }
  vec2 o = vec2(hash(id + 3.1), hash(id + 7.7)) - 0.5;
  float d = length(f - o * 0.7);
  float tw = 0.55 + 0.45 * sin(t * (1.0 + h * 3.0) + h * 40.0);
  float core = smoothstep(0.07, 0.0, d);
  float halo = smoothstep(0.35, 0.0, d) * 0.12;
  return (core + halo) * tw * (h - density) / (1.0 - density);
}

void main() {
  vec2 frag = FlutterFragCoord().xy;
  vec2 p = frag / uSize;
  vec2 uv = frag / uSize.y;
  float t = uTime * 0.035;

  // Base: mostly neutral charcoal with just a trace of indigo.
  vec3 col = mix(vec3(0.018, 0.020, 0.034), vec3(0.035, 0.025, 0.070), p.y);

  // Domain-warped nebula clouds.
  vec2 q = uv * 1.5 + uOffset * 0.15;
  vec2 w = vec2(fbm(q + vec2(t, -t * 0.6)), fbm(q + vec2(5.2, 1.3) - t));
  float n = fbm(q + 2.2 * w + vec2(t * 0.5, -t * 0.3));

  vec3 indigo = vec3(0.20, 0.13, 0.70);
  vec3 violet = vec3(0.49, 0.23, 0.93);
  vec3 magenta = vec3(0.86, 0.28, 0.92);
  vec3 neb = mix(indigo, violet, smoothstep(0.30, 0.70, n));
  neb = mix(neb, magenta, smoothstep(0.55, 0.95, w.x * n * 1.7));
  float mask = smoothstep(0.30, 0.78, n);
  col += neb * mask * 0.34 * uIntensity;

  // Soft orbiting glow orbs.
  vec2 c1 = vec2(0.25 + 0.08 * sin(uTime * 0.21), 0.18 + 0.05 * cos(uTime * 0.17));
  vec2 c2 = vec2(0.85 + 0.06 * cos(uTime * 0.13), 0.72 + 0.07 * sin(uTime * 0.19));
  float aspect = uSize.x / uSize.y;
  vec2 pa = vec2(p.x * aspect, p.y);
  col += violet * 0.11 * smoothstep(0.55, 0.0, length(pa - vec2(c1.x * aspect, c1.y)));
  col += magenta * 0.07 * smoothstep(0.50, 0.0, length(pa - vec2(c2.x * aspect, c2.y)));

  // Two parallax star layers.
  float s = stars(uv + uOffset * 0.04, 70.0, uTime, 0.955)
          + stars(uv + uOffset * 0.09 + 13.0, 32.0, uTime * 1.3, 0.97) * 1.15;
  col += vec3(0.92, 0.86, 1.0) * s * 0.72;

  // Vignette.
  float v = smoothstep(1.15, 0.25, length(p - vec2(0.5, 0.45)));
  col *= mix(0.55, 1.0, v);

  fragColor = vec4(col, 1.0);
}
