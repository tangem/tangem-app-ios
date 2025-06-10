//
//  ProgressDots.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct ProgressDots: View {
    private let style: Style

    @State private var animation1: Bool = false
    @State private var animation2: Bool = false
    @State private var animation3: Bool = false

    init(style: Style) {
        self.style = style
    }

    var body: some View {
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
            .fill(Colors.Icon.accent)
            .frame(width: style.size, height: style.size)
            .scaleEffect(animated ? 0.75 : 1)
            .opacity(animated ? 0.25 : 1)
    }
}

extension ProgressDots {
    private enum Constants {
        static let animation: Animation = .linear(duration: interval * 3).repeatForever(autoreverses: true)
        static let interval: TimeInterval = 0.2
    }

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

#Preview {
    ProgressDots(style: .small)

    ProgressDots(style: .large)
}
