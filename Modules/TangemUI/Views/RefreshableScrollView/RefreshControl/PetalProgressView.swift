//
//  PetalProgressView.swift
//  TangemUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemFoundation

struct PetalProgressView: View {
    let mode: Mode

    private let petals: Int = 8
    private let size: CGFloat = 30
    private let lineWidth: CGFloat = 4
    private let color: Color = Colors.Text.tertiary
    private let centerPadding: CGFloat = 10
    private let minOpacity: Double = 0.2

    private var visiblePetals: Int {
        switch mode {
        case .spinning: petals
        case .progress(let progress): Int(progress * CGFloat(petals))
        }
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            let now = timeline.date.timeIntervalSinceReferenceDate
            let speed = 2.0 // rotate per second
            let phase = now * speed * Double(petals)

            ZStack {
                ForEach(0 ..< visiblePetals, id: \.self) { index in
                    Capsule(style: .circular)
                        .fill(color.opacity(opacity(for: index, phase: phase)))
                        .frame(width: lineWidth, height: size / 3)
                        .offset(y: -centerPadding)
                        .rotationEffect(.degrees(Double(index) / Double(petals) * 360))
                }
            }
            .frame(width: size, height: size)
        }
    }

    private func opacity(for index: Int, phase: Double) -> Double {
        let activeIndex: Int = switch mode {
        case .progress: visiblePetals
        case .spinning: Int(phase) % petals
        }

        // The distance to active index
        let distance = (index - activeIndex + visiblePetals) % visiblePetals

        // How much should it be visible
        let multiplier = 1 - Double(distance) / Double(visiblePetals)
        let maxOpacity: Double = 1

        let opacity: Double = clamp(maxOpacity * multiplier, min: minOpacity, max: maxOpacity)
        return opacity
    }
}

extension PetalProgressView {
    enum Mode {
        case spinning
        /// 0...1
        case progress(CGFloat)
    }
}
