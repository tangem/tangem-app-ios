//
//  SegmentedControl+Lens.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

extension View {
    /// Refracts this view where the pill covers it. The pill itself stays below the labels and is
    /// never drawn here — only the pixels it sits under are bent.
    @ViewBuilder
    func segmentLens(_ geometry: SegmentLensGeometry) -> some View {
        if #available(iOS 26.0, *) {
            modifier(
                SegmentLensPosition(
                    centerX: geometry.center.x,
                    centerY: geometry.center.y,
                    lift: geometry.lift,
                    restingSize: geometry.restingSize
                )
            )
        } else {
            self
        }
    }
}

struct SegmentLensGeometry: Equatable {
    let center: CGPoint
    let restingSize: CGSize
    let lift: CGFloat
}

/// A `Shader`'s uniforms do not interpolate, so the lens has to be handed the same value the pill's
/// own offset and frame are showing on that frame.
///
/// The position and the lift are separate modifiers rather than one `AnimatablePair` because they
/// are driven by different kinds of transaction: a drag moves the pill with no animation at all,
/// while the lift is mid-rise under one. Sharing a single `animatableData` would let the un-animated
/// move retarget the pair as a whole and snap the lift to its end, leaving the lens a full-size
/// capsule around a pill that is still growing.
@available(iOS 26.0, *)
private struct SegmentLensPosition: ViewModifier, Animatable {
    var centerX: CGFloat

    let centerY: CGFloat
    let lift: CGFloat
    let restingSize: CGSize

    var animatableData: CGFloat {
        get { centerX }
        set { centerX = newValue }
    }

    func body(content: Content) -> some View {
        content.modifier(
            SegmentLensLift(
                lift: lift,
                center: CGPoint(x: centerX, y: centerY),
                restingSize: restingSize
            )
        )
    }
}

@available(iOS 26.0, *)
private struct SegmentLensLift: ViewModifier, Animatable {
    var lift: CGFloat

    let center: CGPoint
    let restingSize: CGSize

    var animatableData: CGFloat {
        get { lift }
        set { lift = newValue }
    }

    func body(content: Content) -> some View {
        content.layerEffect(
            ShaderLibrary.bundle(.module).segmentedControlLens(
                .float2(center),
                .float2(size),
                .float(refraction),
                .float(SegmentedControlMetrics.lensDepth)
            ),
            maxSampleOffset: CGSize(width: refraction, height: refraction)
        )
    }

    private var scale: CGFloat {
        1 + (SegmentedControlMetrics.pillLiftScale - 1) * lift
    }

    private var size: CGSize {
        CGSize(width: restingSize.width * scale, height: restingSize.height * scale)
    }

    private var refraction: CGFloat {
        SegmentedControlMetrics.lensRefraction * lift
    }
}
