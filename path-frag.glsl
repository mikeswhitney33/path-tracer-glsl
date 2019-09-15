#version 330

#define NUM_SPHERES 9
#define DIFF 1
#define SPEC 2
#define REFR 3
#define SPHERE(ce, r, e, c, m) Sphere(ce, r, r*r, e, c, m)
#define M_PI 3.1415926535897932384626433832795
#define NUM_SAMPLES 128
// #define vec3 dvec3
// #define float double


in vec3 r;
in vec2 uv;

out vec4 f_color;

uniform float aspect;
uniform float scale;
uniform int sample_i;
uniform sampler2D Texture;

uniform vec2 pixel_dim;


struct Sphere {
    vec3 center;
    float radius;
    float rad2;
    vec3 emission;
    vec3 color;
    int mat;
};

Sphere spheres[NUM_SPHERES] = Sphere[](
    SPHERE(vec3(0, -1e5, 500), 1e5, vec3(0, 0, 0), vec3(.75, .75, .75), DIFF), // floor
    SPHERE(vec3(0, 1e5+500, 500), 1e5, vec3(0, 0, 0), vec3(.75, .75, .75), DIFF), // ceiling
    SPHERE(vec3(0, 0, 1e5+500), 1e5, vec3(0, 0, 0), vec3(.75, .75, .75), DIFF), // back
    SPHERE(vec3(0, 0, -1e5), 1e5, vec3(0, 0, 0), vec3(0, 0, 0), DIFF), // front

    SPHERE(vec3(-1e5-500, 0, 500), 1e5, vec3(0, 0, 0), vec3(.75, .25, .25), DIFF), // left
    SPHERE(vec3(1e5+500, 0, 500), 1e5, vec3(0, 0, 0), vec3(.25, .25, .75), DIFF), // right
    SPHERE(vec3(-500+96, 96, 500-96), 96, vec3(0, 0, 0), vec3(.999, .999, .999), SPEC), //Mirror
    SPHERE(vec3(300, 96, 350), 96, vec3(0, 0, 0), vec3(.999, .999, .999), REFR), //Glass

    SPHERE(vec3(0, 1095, 350), 600, vec3(12, 12, 12), vec3(0, 0, 0), DIFF) //Light
);



float intersect_sphere(vec3 orig, vec3 dir, vec3 center, float rad2) {
    float t0, t1;
    vec3 L = center - orig;
    float tca = dot(L, dir);
    if(tca < 0) return -1.0;
    float d2 = dot(L, L) - tca * tca;
    if(d2 > rad2) return -1.0;
    float thc = sqrt(rad2 - d2);
    t0 = tca - thc;
    t1 = tca + thc;
    if(t0 > t1) {
        float tmp = t0;
        t0 = t1;
        t1 = tmp;
    }
    if(t0 < 0) {
        t0 = t1;
    }
    return t0;
}

int intersect_spheres(vec3 orig, vec3 dir, inout float t) {
    int res = -1;
    t = 1000000000;
    for(int i = 0;i < NUM_SPHERES;i++) {
        Sphere sphere = spheres[i];
        float t0 = intersect_sphere(orig, dir, sphere.center, sphere.rad2);
        if (t0 > 0 && t0 < t) {
            t = t0;
            res = i;
        }
    }
    return res;
}

float noise(vec2 co){
    return 2 * fract(sin(dot(co.xy, vec2(12.9898,78.233))) * 43758.5453) - 1;
}


/**
 * traceRay: traces a ray through the scene
 *
 * orig: the origin of the ray
 * dir: the direction of the ray
 * depth: the number of iterations to trace
 *
 * returns: the color collected by the ray
 */
vec3 traceRay(vec3 orig, vec3 dir) {
    float t = 0;
    int id = 0;


    vec3 cl = vec3(0, 0, 0);
    vec3 cf = vec3(1, 1, 1);
    int depth = 0;
    while(true) {
        id = intersect_spheres(orig, dir, t);
        if(id < 0) return cl;
        Sphere sphere = spheres[id];

        vec3 x = orig + dir * t;
        vec3 normal = normalize(x - sphere.center);
        vec3 nl = dot(normal, dir) < 0 ? normal : -normal;
        vec3 f = sphere.color;
        float p = f.x > f.y && f.x > f.z ? f.x : f.y > f.z ? f.y : f.z;
        cl = cl + cf * sphere.emission;
        if(++depth >= 5) {
            // if (p > noise(normal.xz * sample_i)) {
            //     f = f * (1/p);
            // }
            // else
                return cl;

        }
        cf = cf * f;
        if(sphere.mat == DIFF) {
            float r1 = 2 * M_PI * noise(normal.xy * sample_i);
            float r2 = noise(normal.yx * sample_i);
            float r2s = sqrt(r2);

            vec3 w = nl;
            vec3 u = normalize(cross(abs(w.x) > .1 ? vec3(0, 1, 0) : vec3(1, 0, 0), w));
            vec3 v = cross(w, u);
            vec3 d = normalize(u * cos(r1) * r2s + v * sin(r1) * r2s + w * sqrt(1 - r2));
            dir = d;
            orig = x;
            continue;
        }
        else if(sphere.mat == SPEC) {
            orig = x;
            dir = dir - normal * 2 * dot(normal, dir);
            continue;
        }
        vec3 reflx = x;
        vec3 refld = dir - normal * 2 * dot(normal, dir);
        bool into = dot(normal, nl) > 0;
        float nc = 1;
        float nt = 1.5;
        float nnt = into? nc / nt : nt / nc;
        float ddn = dot(dir, nl);
        float cos2t = 1 - nnt * nnt * (1 - ddn * ddn);
        if(cos2t < 0) {
            orig = reflx;
            dir = refld;
            continue;
        }
        vec3 tdir = normalize(dir * nnt - normal * ((into? 1:-1) * (ddn * nnt + sqrt(cos2t))));
        float a = nt - nc;
        float b = nt + nc;
        float R0 = a * a / (b * b);
        float c = 1 - (into? -ddn : dot(tdir, normal));
        float Re = R0 + (1 - R0) * c * c * c * c * c;
        float Tr = 1 - Re;
        float P = .25 + .5 * Re;
        float RP = Re / P;
        float TP = Tr / (1 - P);

        if (noise(tdir.xz * sample_i) < P) {
            cf = cf * RP;
            orig = reflx;
            dir = refld;
        }
        else {
            cf = cf * TP;
            orig = reflx;
            dir = tdir;
        }
        continue;


    }
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

void main() {
    vec3 orig = vec3(0, 250, -1);
    // vec3 d = normalize(vec3(r.x+noise(uv.xy*time), r.y + noise(uv.yx * time), 1));
    vec3 r2 = vec3(r.xy + pixel_dim * noise(r.yx * sample_i), r.z);
    vec3 d = vec3(r2.x * aspect * scale, r2.y * scale, 1);
    vec3 dir = normalize(d);

    vec3 new_sample = traceRay(orig, dir);
    vec3 avg = texture(Texture, uv).xyz;
    f_color = vec4(rolling_avg(avg, new_sample, sample_i), 1.0);
}