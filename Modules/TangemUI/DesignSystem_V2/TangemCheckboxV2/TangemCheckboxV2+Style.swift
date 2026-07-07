//
//  TangemCheckboxV2+Style.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

extension TangemCheckboxV2 {
    struct Style: ButtonStyle {
        let expandsHitArea: Bool

        @Environment(\.isEnabled) private var isEnabled
        @ScaledMetric private var cornerRadius = Metrics.cornerRadius

        func makeBody(configuration: Configuration) -> some View {
            let isPressed = configuration.isPressed && isEnabled

            let visual = configuration.label
                .background { pressFill(isPressed: isPressed) }
                .clipShape(boxShape)
                .scaleEffect(isPressed ? Metrics.pressScale : 1)
                .compositingGroup()
                .opacity(isEnabled ? 1 : Metrics.disabledOpacity)
                .animation(Animations.pressScale, value: isPressed)

            hitArea(visual)
        }

        @ViewBuilder
        private func hitArea(_ content: some View) -> some View {
            if expandsHitArea {
                content
                    .frame(minWidth: Metrics.minHitTarget, minHeight: Metrics.minHitTarget)
                    .contentShape(Rectangle())
            } else {
                content.contentShape(boxShape)
            }
        }

        private func pressFill(isPressed: Bool) -> some View {
            boxShape
                .fill(DesignSystem.Color.interactionPressDefault)
                .opacity(isPressed ? 1 : 0)
                .animation(Animations.pressColor, value: isPressed)
        }

        private var boxShape: RoundedRectangle {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        }
    }
}

// MARK: - Constants

private extension TangemCheckboxV2.Style {
    enum Metrics {
        static let cornerRadius: CGFloat = 6
        static let pressScale: CGFloat = 0.92
        static let disabledOpacity: CGFloat = 0.4
        static let minHitTarget: CGFloat = 44
    }

    enum Animations {
        static let pressScale = Animation.spring(response: 0.4, dampingFraction: 0.5)
        static let pressColor = Animation.easeInOut(duration: 0.1)
    }
}
