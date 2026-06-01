//
//  MetricsProgressBars.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

// MARK: - MetricsCardContainer

struct MetricsCardContainer<Content: View>: View {
    let backgroundColor: Color
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(.unit(.x4))
            .frame(
                maxWidth: .infinity,
                minHeight: 104,
                alignment: .leading
            )
            .background(
                backgroundColor
            )
            .cornerRadiusContinuous(.unit(.x6))
    }
}

// MARK: - MetricsProgressBar

struct MetricsProgressBar: View {
    let progress: Double
    let foregroundColor: Color
    let backgroundColor: Color

    private let gapSize: CGFloat = .unit(.x1)

    var body: some View {
        GeometryReader { geometry in
            let clampedProgress = min(max(progress, 0), 1)
            let totalWidth = geometry.size.width
            let fillWidth = totalWidth * clampedProgress
            let remainingWidth = totalWidth - fillWidth - gapSize

            HStack(spacing: gapSize) {
                if fillWidth > 0 {
                    Capsule()
                        .fill(foregroundColor)
                        .frame(width: fillWidth)
                }

                if remainingWidth > 0 {
                    Capsule()
                        .fill(backgroundColor)
                }
            }
        }
        .frame(height: .unit(.x1_5))
    }
}

// MARK: - MetricsProgressBarWithDot

struct MetricsProgressBarWithDot: View {
    let progress: Double
    let dotColor: Color
    let backgroundColor: Color

    var body: some View {
        GeometryReader { geometry in
            let fillWidth = geometry.size.width * min(max(progress, 0), 1)

            Capsule()
                .fill(backgroundColor)
                .overlay(alignment: .leading) {
                    ZStack(alignment: .trailing) {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: max(fillWidth, .unit(.x1_5)))

                        Circle()
                            .fill(dotColor)
                            .frame(width: .unit(.x1_5), height: .unit(.x1_5))
                    }
                }
        }
        .frame(height: .unit(.x1_5))
    }
}
