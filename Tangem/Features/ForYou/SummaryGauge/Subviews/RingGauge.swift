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
    static let diameter: CGFloat = 200
    static let defaultLineWidth: CGFloat = 32

    let segments: [GaugeSegment]
    let total: Double
    let selectedID: GaugeSegment.ID?
    let onSelect: ((GaugeSegment.ID?) -> Void)?

    private let lineWidth: CGFloat = RingGauge.defaultLineWidth
    /// Gap between segments, in fractions of the full circle (0...1).
    private let gap: CGFloat = 0.012
    private let baseRingColor: Color = DesignSystem.Color.bgDisabled

    private struct Arc {
        let id: GaugeSegment.ID
        let start: CGFloat
        let end: CGFloat
        let color: Color
    }

    private var denominator: Double {
        max(total, .leastNonzeroMagnitude)
    }

    private var arcs: [Arc] {
        var cursor: CGFloat = 0
        return segments.map { segment in
            let fraction = CGFloat(segment.value / denominator)
            let arc = Arc(id: segment.id, start: cursor + gap / 2, end: cursor + fraction - gap / 2, color: segment.color)
            cursor += fraction
            return arc
        }
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ring
                tapCatcher(in: proxy.size)
            }
            .animation(.easeInOut(duration: 0.2), value: selectedID)
        }
        .frame(width: Self.diameter, height: Self.diameter)
    }

    private var ring: some View {
        ZStack {
            baseRing
            segmentArcs
            selectionOverlay
        }
        .rotationEffect(.degrees(-90))
        .padding(lineWidth / 2) // keep the round caps inside the frame
    }

    private var baseRing: some View {
        Circle()
            .stroke(baseRingColor.shadow(Self.innerShadow), lineWidth: lineWidth)
    }

    private var segmentArcs: some View {
        ForEach(arcs.reversed(), id: \.id) { arc in
            strokedArc(arc)
        }
    }

    @ViewBuilder
    private var selectionOverlay: some View {
        if selectedID != nil {
            Circle()
                .stroke(Self.dimScrim, lineWidth: lineWidth)

            if let arc = arcs.first(where: { $0.id == selectedID }) {
                strokedArc(arc)
            }
        }
    }

    private func tapCatcher(in size: CGSize) -> some View {
        Color.clear
            .contentShape(Rectangle())
            .onTapGesture { location in
                onSelect?(hitTest(location, in: size))
            }
    }

    /// - Figma blur is 2σ while SwiftUI's radius is ~σ, so the blur is halved: 8 → 4.
    private static let innerShadow: ShadowStyle = .inner(color: .white.opacity(0.24), radius: 4, x: 0, y: 4)
    private static let dimScrim: Color = .black.opacity(0.45)

    private func strokedArc(_ arc: Arc) -> some View {
        Circle()
            .trim(from: max(arc.start, 0), to: max(arc.end, arc.start))
            .stroke(
                arc.color.shadow(Self.innerShadow),
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
            )
    }

    /// Returns the id of the tapped slice, or `nil` when the tap misses the ring band.
    private func hitTest(_ location: CGPoint, in size: CGSize) -> GaugeSegment.ID? {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let dx = location.x - center.x
        let dy = location.y - center.y

        let ringRadius = (min(size.width, size.height) - lineWidth) / 2
        guard abs(hypot(dx, dy) - ringRadius) <= lineWidth / 2 else { return nil }

        // Fraction of the circle from 12 o'clock, going clockwise.
        var fraction = atan2(dx, -dy) / (2 * .pi)
        if fraction < 0 { fraction += 1 }

        var cursor = 0.0
        for segment in segments {
            let width = segment.value / denominator
            let start = cursor + Double(gap) / 2
            let end = cursor + width - Double(gap) / 2
            if fraction >= start, fraction < end {
                return segment.id
            }
            cursor += width
        }
        return nil
    }
}
