//
//  TangemCheckboxV2+Mark.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

extension TangemCheckboxV2 {
    struct CheckboxMark: View {
        let value: Value

        @ScaledMetric private var side = Metrics.side

        private var isFilled: Bool { value != .unchecked }

        var body: some View {
            ZStack {
                tinted(DesignSystem.Icons.ControlBox.regular24, color: DesignSystem.Color.iconPrimary)

                tinted(DesignSystem.Icons.ControlBox.filled24, color: DesignSystem.Color.iconPrimary)
                    .scaleEffect(isFilled ? 1 : Metrics.markInScale)
                    .opacity(isFilled ? 1 : 0)
                    .animation(Animations.fill, value: isFilled)

                mark
            }
            .frame(width: side, height: side)
        }

        private var mark: some View {
            ZStack {
                switch value {
                case .unchecked:
                    EmptyView()
                case .checked:
                    tinted(DesignSystem.Icons.ControlCheckmark.regular24, color: DesignSystem.Color.iconInverse)
                        .transition(Animations.markTransition)
                case .indeterminate:
                    tinted(DesignSystem.Icons.ControlIndeterminate.regular24, color: DesignSystem.Color.iconInverse)
                        .transition(Animations.markTransition)
                }
            }
            .animation(Animations.mark, value: value)
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

private extension TangemCheckboxV2.CheckboxMark {
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
