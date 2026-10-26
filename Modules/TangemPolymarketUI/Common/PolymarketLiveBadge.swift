//
//  PolymarketLiveBadge.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

public struct PolymarketLiveBadge: View {
    private let isPulsing: Bool

    public init(isPulsing: Bool) {
        self.isPulsing = isPulsing
    }

    public var body: some View {
        if isPulsing {
            badge
                .slotStart { PulsingDot() }
        } else {
            badge
                .slotStart(DesignSystem.Icons.Dot.filled12)
        }
    }

    private var badge: Badge<EmptyView, EmptyView> {
        Badge(label: Localization.predictionEventLive, accessibilityLabel: nil)
            .size(.x4)
            .variant(.solid)
            .appearance(.success)
    }
}

// MARK: - PulsingDot

private struct PulsingDot: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if reduceMotion {
            dot(opacity: 1)
        } else {
            TimelineView(.animation) { context in
                dot(opacity: Self.opacity(at: context.date))
            }
        }
    }

    private func dot(opacity: Double) -> some View {
        DesignSystem.Icons.Dot.filled12.image
            .renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundStyle(DesignSystem.Color.iconStaticDark)
            .opacity(opacity)
    }

    private static func opacity(at date: Date) -> Double {
        let phase = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: Constants.period) / Constants.period
        let wave = (1 + cos(2 * Double.pi * phase)) / 2

        return Constants.dimmedOpacity + (1 - Constants.dimmedOpacity) * wave
    }
}

// MARK: - Constants

private extension PulsingDot {
    enum Constants {
        static let dimmedOpacity: Double = 0.35
        static let period: TimeInterval = 1.2
    }
}
