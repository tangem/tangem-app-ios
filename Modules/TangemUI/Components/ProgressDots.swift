//
//  ProgressDots.swift
//  TangemUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

public struct ProgressDots: View {
    private let style: Style

    @ScaledMetric private var circleSizeSide: CGFloat

    @State private var animation1: Bool = false
    @State private var animation2: Bool = false
    @State private var animation3: Bool = false

    public init(style: Style) {
        self.style = style
        _circleSizeSide = ScaledMetric(wrappedValue: style.size)
    }

    public var body: some View {
        HStack(spacing: style.spacing) {
            circle(animated: animation1)

            circle(animated: animation2)

            circle(animated: animation3)
        }
        .fixedSize()
        .onAppear {
            withAnimation(Constants.animation) {
                animation1 = true
            }

            withAnimation(Constants.animation.delay(Constants.interval)) {
                animation2 = true
            }

            withAnimation(Constants.animation.delay(Constants.interval * 2)) {
                animation3 = true
            }
        }
        .onDisappear {
            withAnimation(.none) {
                animation1 = false
                animation2 = false
                animation3 = false
            }
        }
    }

    private func circle(animated: Bool) -> some View {
        Circle()
            .fill(Color.Tangem.Graphic.Status.accent)
            .frame(width: circleSizeSide, height: circleSizeSide)
            .scaleEffect(animated ? 0.75 : 1)
            .opacity(animated ? 0.25 : 1)
    }
}

// MARK: - Constants

private extension ProgressDots {
    enum Constants {
        static let animation: Animation = .linear(duration: interval * 3).repeatForever(autoreverses: true)
        static let interval: TimeInterval = 0.2
    }
}

// MARK: - Style

public extension ProgressDots {
    enum Style: Hashable {
        case small
        case large

        var size: CGFloat {
            switch self {
            case .small: 3
            case .large: 8
            }
        }

        var spacing: CGFloat {
            switch self {
            case .small: 3
            case .large: 6
            }
        }
    }
}

// MARK: - Previews

#if DEBUG

#Preview {
    VStack(spacing: 20) {
        ProgressDots(style: .small)

        ProgressDots(style: .large)
    }
}

#endif // DEBUG
