#include <metal_stdlib>
using namespace metal;

template<typename  T>
T glsl_mod(T x, T y) {
    return x - y * floor(x / y);
}

float4 permute(float4 x) {
    float4 step1 = x * 34.0;
    float4 step2 = step1 + 1.0;
    float4 step3 = step2 * x;
    return glsl_mod(step3, float4(289.0));
}

float4 taylorInvSqrt(float4 r) {
    return 1.79284291400159 - 0.85373472095314 * r;
}

float snoise(float3 v) {
    const float2 C = float2(1.0 / 6.0, 1.0 / 3.0);
    const float4 D = float4(0.0, 0.5, 1.0, 2.0);

    float3 i = floor(v + dot(v, C.yyy));
    float3 x0 = v - i + dot(i, C.xxx);

    float3 g = step(x0.yzx, x0.xyz);
    float3 l = 1.0 - g;
    float3 i1 = min(g.xyz, l.zxy);
    float3 i2 = max(g.xyz, l.zxy);

    float3 x1 = x0 - i1 + C.xxx;
    float3 x2 = x0 - i2 + 2.0 * C.xxx;
    float3 x3 = x0 - 1.0 + 3.0 * C.xxx;

    i = glsl_mod(i, float3(289.0));
    float4 p = permute(permute(permute(
        i.z + float4(0.0, i1.z, i2.z, 1.0))
      + i.y + float4(0.0, i1.y, i2.y, 1.0))
      + i.x + float4(0.0, i1.x, i2.x, 1.0));

    float n_ = 1.0 / 7.0;
    float3 ns = n_ * D.wyz - D.xzx;

    float4 j = p - 49.0 * floor(p * ns.z * ns.z);

    float4 x_ = floor(j * ns.z);
    float4 y_ = floor(j - 7.0 * x_);

    float4 x = x_ * ns.x + ns.yyyy;
    float4 y = y_ * ns.x + ns.yyyy;
    float4 h = 1.0 - abs(x) - abs(y);

    float4 b0 = float4(x.xy, y.xy);
    float4 b1 = float4(x.zw, y.zw);

    float4 s0 = floor(b0) * 2.0 + 1.0;
    float4 s1 = floor(b1) * 2.0 + 1.0;
    float4 sh = -step(h, float4(0.0));

    float4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
    float4 a1 = b1.xzyw + s1.xzyw * sh.zzww;

    float3 p0 = float3(a0.xy, h.x);
    float3 p1 = float3(a0.zw, h.y);
    float3 p2 = float3(a1.xy, h.z);
    float3 p3 = float3(a1.zw, h.w);

    float4 norm = taylorInvSqrt(float4(dot(p0, p0), dot(p1, p1), dot(p2, p2), dot(p3, p3)));
    p0 *= norm.x;
    p1 *= norm.y;
    p2 *= norm.z;
    p3 *= norm.w;

    float4 m = max(0.6 - float4(dot(x0, x0), dot(x1, x1), dot(x2, x2), dot(x3, x3)), 0.0);
    m = m * m;
    return 42.0 * dot(m * m, float4(dot(p0, x0), dot(p1, x1), dot(p2, x2), dot(p3, x3)));
}

// MARK: - Uniforms

struct Uniforms {
    float uTime;
    float2 uResolution;
    // 5 colors packed as float3 (sRGB gamma-encoded)
    float3 uColor0;
    float3 uColor1;
    float3 uColor2;
    float3 uColor3;
    float3 uColor4; // background
};

// MARK: - Vertex shader (full-screen triangle)

struct VertexOut {
    float4 position [[ position ]];
    float2 uv;
};

vertex VertexOut northernLightsVertex(uint vid [[ vertex_id ]]) {
    // Full-screen triangle using 3 vertices that cover clip space [-1,1]
    float2 positions[3] = { float2(-1, -1), float2(3, -1), float2(-1, 3) };
    float2 uvs[3]       = { float2(0, 0),   float2(2, 0),  float2(0, 2) };

    VertexOut out;
    out.position = float4(positions[vid], 0, 1);
    out.uv = uvs[vid];
    return out;
}

// MARK: - Fragment shader

fragment half4 northernLightsFragment(
    VertexOut in [[ stage_in ]],
    constant Uniforms &u [[ buffer(0) ]]
) {
    const int MAX_COLORS = 5;
    const float SCALE = 4.0;
    const float SPEED = 0.5;

    float3 uColor[5] = { u.uColor0, u.uColor1, u.uColor2, u.uColor3, u.uColor4 };

    // Convert UV [0,1] to pixel coordinates (Y flipped: UV y=0 is bottom, fragCoord y=0 is top)
    float2 fragCoord = float2(in.uv.x * u.uResolution.x, (1.0 - in.uv.y) * u.uResolution.y);

    float mr = min(u.uResolution.x, u.uResolution.y);
    float2 uv = (fragCoord * SCALE - float2(u.uResolution)) / mr;
    float2 base = uv / 2.0;

    float2 frequency = float2(0.7, 0.3);
    const float noiseFloor = 0.00001;
    float t = u.uTime * 0.01506;

    float3 vColor = uColor[MAX_COLORS - 1];

    for (int i = 0; i < MAX_COLORS - 1; i++) {
        float flow  = 5.0 + float(i) * 0.3;
        float speed = 6.0 * SPEED + float(i) * 0.3;
        float seed  = 1.0 + float(i) * 4.0;
        float noiseCeil = 0.6 + float(i) * 0.07;

        float n = smoothstep(noiseFloor, noiseCeil,
            snoise(float3(
                base.x * frequency.x,
                base.y * frequency.y - t * flow,
                t * speed + seed
            ))
        );

        vColor = mix(vColor, uColor[i], n);
    }

    float3 ambient = float3(0.0);
    for (int j = 0; j < MAX_COLORS - 1; j++) {
        ambient += uColor[j];
    }
    ambient = ambient / float(MAX_COLORS - 1) * 0.5;
    vColor = max(vColor, ambient);

    float2 topCenter = float2(u.uResolution.x * 0.5, 0.0);
    float2 delta     = fragCoord - topCenter;
    float2 radii     = float2(u.uResolution.x * 0.9, u.uResolution.y * 0.65);
    float normDist   = length(delta / radii);
    float alpha      = pow(1.0 - smoothstep(0.0, 1.0, normDist), 1.5);

    half3 bg = half3(uColor[MAX_COLORS - 1]);
    half3 composited = half3(vColor) * half(alpha) + bg * (1.0h - half(alpha));
    return half4(composited, 1.0h);
}
