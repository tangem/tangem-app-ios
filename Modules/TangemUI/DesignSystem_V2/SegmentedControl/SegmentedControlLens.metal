//
//  SegmentedControlLens.metal
//  TangemModules
//
//  Created by Mikhail Andreev on 03.09.2026.
//  Copyright © 2026 Tangem AG. All rights reserved.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>

using namespace metal;

static float capsuleDistance(float2 point, float2 halfSize, float radius) {
    float2 q = abs(point) - halfSize + radius;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - radius;
}

/// Bends the layer inwards along the capsule's edge, leaving its interior and everything outside it
/// untouched: the pill reads as a lens over the labels without a translucent surface sitting on top
/// of them.
[[stitchable]] half4 segmentedControlLens(
    float2 position,
    SwiftUI::Layer layer,
    float2 center,
    float2 size,
    float refraction,
    float depth
) {
    if (refraction <= 0.0 || depth <= 0.0) {
        return layer.sample(position);
    }

    float2 halfSize = size * 0.5;
    float radius = min(halfSize.x, halfSize.y);
    float2 local = position - center;

    float distance = capsuleDistance(local, halfSize, radius);

    if (distance > 0.0) {
        return layer.sample(position);
    }

    float2 gradient = float2(
        capsuleDistance(local + float2(1.0, 0.0), halfSize, radius) - capsuleDistance(local - float2(1.0, 0.0), halfSize, radius),
        capsuleDistance(local + float2(0.0, 1.0), halfSize, radius) - capsuleDistance(local - float2(0.0, 1.0), halfSize, radius)
    );

    float gradientLength = length(gradient);

    // The gradient vanishes at the capsule's centre, where the bend is zero anyway — normalizing it
    // there would poison the sample with NaN.
    if (gradientLength < 1e-4) {
        return layer.sample(position);
    }

    float edge = 1.0 - smoothstep(0.0, depth, -distance);
    float bend = edge * edge * refraction;

    return layer.sample(position - (gradient / gradientLength) * bend);
}
