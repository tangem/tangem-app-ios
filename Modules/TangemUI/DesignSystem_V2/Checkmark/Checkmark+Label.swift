//
//  Checkmark+Label.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

public extension Checkmark {
    struct Label: View {
        let value: Value
        let size: Size

        @ScaledMetric private var side: CGFloat

        public init(value: Value, size: Size) {
            self.value = value
            self.size = size
            _side = ScaledMetric(wrappedValue: size.side)
        }

        public init(isChecked: Bool) {
            self.init(value: isChecked ? .checked : .unchecked, size: .size24)
        }

        private var checked: Bool { value == .checked }

        private var circleColor: Color {
            value == .error ? DesignSystem.Color.iconStatusError : DesignSystem.Color.iconPrimary
        }

        public var body: some View {
            ZStack {
                tinted(SelectionControlGlyph.circleRegular, color: circleColor)

                tinted(SelectionControlGlyph.circleFilled, color: DesignSystem.Color.iconPrimary)
                    .scaleEffect(checked ? 1 : Metrics.markInScale)
                    .opacity(checked ? 1 : 0)
                    .animation(Animations.fill, value: checked)

                mark
            }
            .frame(width: side, height: side)
        }

        private var mark: some View {
            ZStack {
                if checked {
                    tinted(SelectionControlGlyph.checkmark, color: DesignSystem.Color.iconInverse)
                        .transition(Animations.markTransition)
                }
            }
            .animation(Animations.mark, value: checked)
        }

        private func tinted(_ glyph: SelectionControlGlyph, color: Color) -> some View {
            glyph.image(for: size).image
                .renderingMode(.template)
                .resizable()
                .frame(width: side, height: side)
                .foregroundStyle(color)
        }
    }
}

// MARK: - Constants

private extension Checkmark.Label {
    enum Metrics {
        static let markInScale: CGFloat = 0.5
    }

    enum Animations {
        static let fill = Animation.easeInOut(duration: 0.15)
        static let mark = Animation.spring(response: 0.35, dampingFraction: 0.5)

        static let markTransition: AnyTransition = .scale(scale: Metrics.markInScale).combined(with: .opacity)
    }
}
