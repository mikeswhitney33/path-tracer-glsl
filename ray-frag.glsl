#version 330

#define EPSILON 1e-8

in vec3 r;
in vec2 uv;

out vec4 f_color;

uniform float aspect;
uniform float scale;
uniform int sample_i;
uniform sampler2D Texture;

uniform vec2 pixel_dim;

struct Material {
    vec3 cDiffuse;
    float kDiffuse;
};

struct Triangle {
    vec3 A, B, C;
    Material mat;
};

#define NUM_TRIANGLES 1

Triangle triangles[NUM_TRIANGLES];

void initTriangles() {
    triangles[0] = Triangle(vec3(-0.8, -0.8, 0.0), vec3(0.8, -0.8, 0.0), vec3(0.0, 0.8, 0.0), Material(vec3(0.75, 0.25, 0.25), 0.2));
}

// void initTriangles() {}

void initScene() {
    initTriangles();
}

/** 
 * randf: generates a random float between 0 and 1
 * 
 * co: the seed for the random number generator
 * 
 * returns: a random number between 0 and 1
 */
float randf(vec2 co){
    return 2 * fract(sin(dot(co.xy, vec2(12.9898,78.233))) * 43758.5453) - 1;
}

/**
 * rolling_avg: calculates a rolling average
 *
 * avg:         the current average
 * new_sample:  a new sample to add in to the average
 * N:           the new number of samples
 *
 * returns:     the new average
 */
vec3 rolling_avg(vec3 avg, vec3 new_sample, int N) {
    return (new_sample + (N * avg)) / (N+1);
}

/**
 * ray_triangle_intersection: tests for the intersection between a ray and a triangle
 * 
 * orig: the origin of the ray
 * dir: the direction of the ray
 * A: the first point on the triangle
 * B: the second point on the triangle
 * C: the third point on the triangle
 * t: the current t value 
 * 
 * returns: true if intersection happens, false otherwise.
 */
bool ray_triangle_intersection(vec3 orig, vec3 dir, vec3 A, vec3 B, vec3 C, inout float t) {
    vec3 AB = B - A;
    vec3 AC = C - A;
    vec3 h = cross(dir, AC);
    float a = dot(AB, h);
    if(a > -EPSILON && a < EPSILON) {
        return false;
    }
    float f = 1.0 / a;
    vec3 s = orig - A;
    float u = f * dot(s, h);
    if(u < 0.0 || u > 1.0) {
        return false;
    }
    vec3 q = cross(s, AB);
    float v = f * dot(dir, q);
    if(v < 0.0 || u + v > 1.0) {
        return false;
    }
    float _t = f * dot(AC, q);
    if(_t < EPSILON || _t > t) {
        return false;
    }
    else {
        t = _t;
        return true;
    }
}

bool intersect(vec3 orig, vec3 dir, out float t, out int id) {
    t = 1e8;
    id = -1;
    for(int i = 0;i < NUM_TRIANGLES;i++) {
        if(ray_triangle_intersection(orig, dir, triangles[i].A, triangles[i].B, triangles[i].C, t)) {
            id = i;
        }
    }
    return id >= 0;
}

/**
 * traceRay: traces a ray through the scene.
 * 
 * orig: the origin of the ray 
 * dir: the direction of the ray
 * 
 * returns: the color collected from the ray.
 */
vec3 traceRay(vec3 orig, vec3 dir) {
    float t;
    int id;
    if(intersect(orig, dir, t, id)) {
        return triangles[id].mat.cDiffuse;
    }
    return vec3(0, 0, 0);
}

void main() {
    initTriangles();
    vec3 orig = vec3(0, 0, -1);
    vec3 r2 = vec3(r.xy + pixel_dim * randf(r.yx * sample_i), r.z);
    vec3 d = vec3(r2.x * aspect * scale, r2.y * scale, 1);
    vec3 dir = normalize(d);

    vec3 new_sample = traceRay(orig, dir);
    vec3 avg = texture(Texture, uv).xyz;
    f_color = vec4(rolling_avg(avg, new_sample, sample_i), 1.0);
}