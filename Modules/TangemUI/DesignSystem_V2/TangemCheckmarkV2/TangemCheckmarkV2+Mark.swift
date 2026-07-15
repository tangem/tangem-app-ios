//
//  TangemCheckmarkV2+Mark.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

extension TangemCheckmarkV2 {
    struct CheckmarkMark: View {
        let checked: Bool

        @ScaledMetric private var side = Metrics.side

        var body: some View {
            ZStack {
                tinted(DesignSystem.Icons.ControlCircle.regular24, color: DesignSystem.Color.iconPrimary)

                tinted(DesignSystem.Icons.ControlCircle.filled24, color: DesignSystem.Color.iconPrimary)
                    .scaleEffect(checked ? 1 : Metrics.markInScale)
                    .opacity(checked ? 1 : 0)
                    .animation(Animations.fill, value: checked)

                mark
            }
            .frame(width: side, height: side)
        }

        @ViewBuilder
        private var mark: some View {
            ZStack {
                if checked {
                    tinted(DesignSystem.Icons.ControlCheckmark.regular24, color: DesignSystem.Color.iconInverse)
                        .transition(Animations.markTransition)
                }
            }
            .animation(Animations.mark, value: checked)
        }

        private func tinted(_ icon: ImageType, color: Color) -> some View {
            icon.image
                .renderingMode(.template)
                .resizable()
                .frame(width: side, height: side)
                .foregroundStyle(color)
        }
    }
}

// MARK: - Constants

private extension TangemCheckmarkV2.CheckmarkMark {
    enum Metrics {
        static let side: CGFloat = 24
        static let markInScale: CGFloat = 0.5
    }

    enum Animations {
        static let fill = Animation.easeInOut(duration: 0.15)
        static let mark = Animation.spring(response: 0.35, dampingFraction: 0.5)

        static let markTransition: AnyTransition = .scale(scale: Metrics.markInScale).combined(with: .opacity)
    }
}
