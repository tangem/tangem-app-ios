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

    @State private var dimProgress: CGFloat = 0
    /// Latches the last selected slice so it stays bright while the dim springs out after deselection.
    @State private var highlightedID: GaugeSegment.ID?

    private let lineWidth: CGFloat = Constants.defaultLineWidth
    private let baseRingColor: Color = DesignSystem.Color.borderPrimary

    private struct Arc: Identifiable {
        let id: GaugeSegment.ID
        let start: CGFloat
        let end: CGFloat
        let color: Color
    }

    private var denominator: Double {
        max(total, .leastNonzeroMagnitude)
    }

    /// The centerline diameter the round-cap compensation and hit-test are measured against.
    private var arcDiameter: CGFloat {
        Constants.diameter - lineWidth
    }

    /// Visual (floored) sweeps in degrees, one per segment — tiny holdings kept ≥ 7% of the circle.
    private var sweepsDeg: [CGFloat] {
        let weights = segments.map { CGFloat($0.value / denominator) }
        let capDeg = GaugeSweeps.lastSegmentOverlapDeg(strokeWidth: lineWidth, arcDiameter: arcDiameter)
        return GaugeSweeps.visualSweepAngles(weights: weights, capDeg: capDeg)
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
        ZStack {
            baseRing

            ZStack {
                if dimProgress > 0 {
                    Circle().stroke(dimColor, lineWidth: lineWidth)
                }

                ForEach(arcs.reversed()) { arc in
                    ZStack {
                        strokedArc(arc)

                        if dimProgress > 0, arc.id != highlightedID {
                            dimArc(arc)
                        }
                    }
                }
            }
            .rotationEffect(.degrees(-90))
        }
        .padding(lineWidth / 2) // keep the round caps inside the frame
    }

    private var baseRing: some View {
        Circle()
            .stroke(baseRingColor, lineWidth: lineWidth)
            .overlay { ringInnerShadow }
    }

    private var ringInnerShadow: some View {
        Circle()
            .stroke(.white, lineWidth: lineWidth)
            .overlay {
                Circle()
                    .stroke(.black, lineWidth: lineWidth)
                    .blur(radius: Constants.innerShadowBlur)
                    .offset(y: Constants.innerShadowOffsetY)
                    .blendMode(.destinationOut)
            }
            .compositingGroup()
            .opacity(Constants.innerShadowOpacity)
            .mask { Circle().stroke(.black, lineWidth: lineWidth) }
    }

    private func tapCatcher(in size: CGSize) -> some View {
        Color.clear
            .contentShape(Rectangle())
            .onTapGesture { location in
                let hit = hitTest(location, in: size)
                // Re-tapping the already-selected slice is a no-op; deselect happens only on a miss.
                guard hit != selectedID else { return }
                onSelect?(hit)
            }
    }

    /// Selection dim: the theme-inverting 20% token scaled by the animated progress so it fades in/out.
    private var dimColor: Color {
        DesignSystem.Color.borderInverseTertiary.opacity(dimProgress)
    }

    private func strokedArc(_ arc: Arc) -> some View {
        Circle()
            .trim(from: max(arc.start, 0), to: max(arc.end, arc.start))
            .stroke(
                arc.color.shadow(Constants.innerShadow),
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
            )
    }

    private func dimArc(_ arc: Arc) -> some View {
        Circle()
            .trim(from: max(arc.start, 0), to: max(arc.end, arc.start))
            .stroke(dimColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
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

        // Same floored geometry as the draw pass, so hits line up with the drawn arcs.
        for arc in arcs where fraction >= arc.start && fraction < arc.end {
            return arc.id
        }
        return nil
    }
}

// MARK: - Constants

extension RingGauge {
    enum Constants {
        static let diameter: CGFloat = 200
        static let defaultLineWidth: CGFloat = 28

        static let innerShadowBlur: CGFloat = 4
        static let innerShadowOffsetY: CGFloat = 4
        static let innerShadowOpacity: CGFloat = 0.24
        static let innerShadow: ShadowStyle = .inner(
            color: .white.opacity(innerShadowOpacity),
            radius: innerShadowBlur,
            x: 0,
            y: innerShadowOffsetY
        )

        /// The same spring as the segment tooltip's pop-in, so the dim and the tooltip move together
        /// (dampingRatio 0.82, stiffness 1100 → damping coefficient 2·0.82·√1100 ≈ 54.4 at mass 1).
        static let dimSpring: Animation = .interpolatingSpring(mass: 1, stiffness: 1100, damping: 54.4)
    }
}
