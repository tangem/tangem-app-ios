//
//  RingGauge.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct RingGauge: View {
    let segments: [GaugeSegment]
    let total: Double
    let selectedID: GaugeSegment.ID?
    let onSelect: ((GaugeSegment.ID?) -> Void)?
    /// Reports every tap that lands on a slice, whether or not it changes the selection.
    var onSegmentTap: (() -> Void)? = nil

    @State private var dimProgress: CGFloat = 0
    /// Latches the last selected slice so it stays bright while the dim springs out after deselection.
    @State private var highlightedID: GaugeSegment.ID?

    private let lineWidth: CGFloat = Constants.defaultLineWidth
    private let baseRingColor: Color = DesignSystem.Color.borderPrimary

    typealias Arc = RingArc

    private var denominator: Double {
        max(total, .leastNonzeroMagnitude)
    }

    /// The centerline diameter the hit-test is measured against.
    private var arcDiameter: CGFloat {
        Constants.diameter - lineWidth
    }

    /// Visual (floored) sweeps in degrees, one per segment — tiny holdings kept ≥ 1% of the circle.
    private var sweepsDeg: [CGFloat] {
        let weights = segments.map { CGFloat($0.value / denominator) }
        return GaugeSweeps.visualSweepAngles(weights: weights)
    }

    /// Contiguous arcs (no angular gap) laid out from the floored sweeps; zero-weight slices are dropped.
    private var arcs: [Arc] {
        let sweeps = sweepsDeg
        var cursorDeg: CGFloat = 0
        var result: [Arc] = []
        for (index, segment) in segments.enumerated() {
            let sweep = sweeps[index]
            defer { cursorDeg += sweep }
            guard sweep > 0 else { continue }
            result.append(
                Arc(
                    id: segment.id,
                    start: cursorDeg / 360,
                    end: (cursorDeg + sweep) / 360,
                    color: segment.color
                )
            )
        }
        return result
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ring
                tapCatcher(in: proxy.size)
            }
        }
        .frame(width: Constants.diameter, height: Constants.diameter)
        .onChange(of: selectedID) { newValue in
            if let newValue {
                highlightedID = newValue
            }
            withAnimation(Constants.dimSpring) {
                dimProgress = newValue != nil ? 1 : 0
            }
        }
    }

    private var ring: some View {
        RingCanvas(
            arcs: arcs,
            lineWidth: lineWidth,
            baseColor: baseRingColor,
            highlightedID: highlightedID,
            dimProgress: dimProgress
        )
    }

    /// How far a round cap bulges past its body, as a fraction of the circle.
    private var capFraction: CGFloat {
        GaugeSweeps.capOverlapDeg(strokeWidth: lineWidth, arcDiameter: arcDiameter) / GaugeSweeps.Constants.fullCircleDeg
    }

    private func tapCatcher(in size: CGSize) -> some View {
        Color.clear
            .contentShape(Rectangle())
            .onTapGesture { location in
                let hit = hitTest(location, in: size)

                if hit != nil {
                    onSegmentTap?()
                }

                // Re-tapping the already-selected slice is a no-op; deselect happens only on a miss.
                guard hit != selectedID else { return }
                onSelect?(hit)
            }
    }

    /// Returns the id of the tapped slice, or `nil` when the tap misses the ring band.
    private func hitTest(_ location: CGPoint, in size: CGSize) -> GaugeSegment.ID? {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let dx = location.x - center.x
        let dy = location.y - center.y

        let ringRadius = (min(size.width, size.height) - lineWidth) / 2
        // Widen the touch target beyond the stroke on both edges (stroke/2 + stroke·0.4).
        let tolerance = lineWidth / 2 + lineWidth * 0.4
        guard abs(hypot(dx, dy) - ringRadius) <= tolerance else { return nil }

        // Fraction of the circle from 12 o'clock, going clockwise.
        var fraction = atan2(dx, -dy) / (2 * .pi)
        if fraction < 0 { fraction += 1 }

        // A body is covered at its start by the predecessor's cap and extended past its end by its own, so
        // what the eye reads as a slice sits one cap ahead of its sweep. Shifting the tap back by that much
        // keeps a tap on the pill you see, which matters most for a floored slice narrower than the cap.
        fraction = (fraction - capFraction + 1).truncatingRemainder(dividingBy: 1)

        for arc in arcs where fraction >= arc.start && fraction < arc.end {
            return arc.id
        }
        return nil
    }
}

// MARK: - Arc

struct RingArc: Identifiable {
    let id: GaugeSegment.ID
    let start: CGFloat
    let end: CGFloat
    let color: Color
}

// MARK: - Canvas

/// Bodies are butt-capped, so each covers exactly its own sweep; the rounding comes from a second pass of
/// forward half-caps. Painting every cap after every body lets the last slice's cap land on slice 0, which
/// closes the wrap seam with no special case and keeps the overlap pointing one way all around.
///
/// `Animatable` on the view, not on a shape: a `Canvas` has no animatable input of its own, so without the
/// conformance the dim would jump to its final value in a single frame instead of springing in.
private struct RingCanvas: View, Animatable {
    let arcs: [RingArc]
    let lineWidth: CGFloat
    let baseColor: Color
    let highlightedID: GaugeSegment.ID?
    var dimProgress: CGFloat

    var animatableData: CGFloat {
        get { dimProgress }
        set { dimProgress = newValue }
    }

    /// Selection dim: the theme-inverting token scaled by the animated progress so it fades in and out.
    private var dimColor: Color {
        DesignSystem.Color.borderInverseTertiary.opacity(dimProgress)
    }

    private var bodyStroke: StrokeStyle {
        StrokeStyle(lineWidth: lineWidth, lineCap: .butt)
    }

    var body: some View {
        Canvas { context, size in
            let painted = arcs.reversed()
            let box = CGRect(origin: .zero, size: size).insetBy(dx: lineWidth / 2, dy: lineWidth / 2)

            context.stroke(Path(ellipseIn: box), with: .color(baseColor), lineWidth: lineWidth)

            if dimProgress > 0 {
                context.stroke(Path(ellipseIn: box), with: .color(dimColor), lineWidth: lineWidth)
            }

            for arc in painted {
                context.stroke(bodyPath(of: arc, in: box), with: .color(arc.color), style: bodyStroke)

                if dimProgress > 0, arc.id != highlightedID {
                    context.stroke(bodyPath(of: arc, in: box), with: .color(dimColor), style: bodyStroke)
                }
            }

            for arc in painted {
                context.fill(capPath(at: arc.end, in: box), with: .color(arc.color))

                if dimProgress > 0, arc.id != highlightedID {
                    context.fill(capPath(at: arc.end, in: box), with: .color(dimColor))
                }
            }
        }
    }

    private func bodyPath(of arc: RingArc, in box: CGRect) -> Path {
        Path { path in
            path.addArc(
                center: CGPoint(x: box.midX, y: box.midY),
                radius: box.width / 2,
                startAngle: .degrees(angleDeg(at: arc.start)),
                endAngle: .degrees(angleDeg(at: max(arc.end, arc.start))),
                clockwise: false
            )
        }
    }

    /// Half of a round cap: a disc of one cap radius on the centerline, split by the ring's radius at that
    /// angle, keeping the half that bulges forward over the slice's successor.
    private func capPath(at fraction: CGFloat, in box: CGRect) -> Path {
        let angle = Angle.degrees(angleDeg(at: fraction))
        let radius = box.width / 2
        let center = CGPoint(
            x: box.midX + radius * cos(angle.radians),
            y: box.midY + radius * sin(angle.radians)
        )

        return Path { path in
            path.addArc(
                center: center,
                radius: lineWidth / 2,
                startAngle: angle,
                endAngle: angle + .degrees(180),
                clockwise: false
            )
            path.closeSubpath()
        }
    }

    /// Ring fractions start at 12 o'clock and run clockwise; the drawing angles start at 3 o'clock.
    private func angleDeg(at fraction: CGFloat) -> CGFloat {
        fraction * GaugeSweeps.Constants.fullCircleDeg - 90
    }
}

// MARK: - Constants

extension RingGauge {
    enum Constants {
        static let diameter: CGFloat = 200
        static let defaultLineWidth: CGFloat = 28

        /// The same spring as the segment tooltip's pop-in, so the dim and the tooltip move together
        /// (dampingRatio 0.82, stiffness 1100 → damping coefficient 2·0.82·√1100 ≈ 54.4 at mass 1).
        static let dimSpring: Animation = .interpolatingSpring(mass: 1, stiffness: 1100, damping: 54.4)
    }
}
