//
//  MarketIndexScaleView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct MarketIndexScaleView: View {
    enum Size {
        case small
        case big

        var indicatorSide: CGFloat {
            switch self {
            case .small: 10
            case .big: 12
            }
        }

        var trackHeight: CGFloat {
            switch self {
            case .small: 4
            case .big: 6
            }
        }
    }

    let progress: CGFloat
    let size: Size

    @ScaledMetric private var indicatorSide: CGFloat
    @ScaledMetric private var trackHeight: CGFloat

    init(progress: CGFloat, size: Size) {
        self.progress = progress
        self.size = size
        _indicatorSide = ScaledMetric(wrappedValue: size.indicatorSide)
        _trackHeight = ScaledMetric(wrappedValue: size.trackHeight)
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Self.gradient)
                    .frame(height: trackHeight)

                Circle()
                    .fill(DesignSystem.Color.iconPrimary)
                    .frame(size: CGSize(bothDimensions: indicatorSide))
                    .offset(x: proxy.size.width * progress.clampedToUnitInterval - indicatorSide / 2)
            }
        }
        .frame(height: indicatorSide)
    }

    private static let gradient = LinearGradient(
        colors: [
            DesignSystem.Color.iconAccentRed,
            DesignSystem.Color.iconAccentOrange,
            DesignSystem.Color.iconAccentYellow,
            DesignSystem.Color.iconAccentGreen,
            DesignSystem.Color.iconAccentBlue,
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
}

// MARK: - Appearance colour

extension MarketCapViewModel.Metric.Appearance {
    var textColor: Color {
        switch self {
        case .red: DesignSystem.Color.textAccentRed
        case .yellow: DesignSystem.Color.textAccentYellow
        case .green: DesignSystem.Color.textAccentGreen
        case .blue: DesignSystem.Color.textAccentBlue
        }
    }
}

// MARK: - Private

private extension CGFloat {
    var clampedToUnitInterval: CGFloat {
        Swift.min(Swift.max(self, 0), 1)
    }
}

// MARK: - Previews

#Preview {
    VStack(spacing: 32) {
        MarketIndexScaleView(progress: 0.13, size: .small)
        MarketIndexScaleView(progress: 0.45, size: .small)
        MarketIndexScaleView(progress: 0.73, size: .big)
    }
    .padding()
}
