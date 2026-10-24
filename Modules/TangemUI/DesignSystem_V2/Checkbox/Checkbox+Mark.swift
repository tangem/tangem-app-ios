//
//  Checkbox+Mark.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

extension Checkbox {
    struct CheckboxMark: View {
        let value: Value
        let size: Size

        @ScaledMetric private var side: CGFloat

        init(value: Value, size: Size) {
            self.value = value
            self.size = size
            _side = ScaledMetric(wrappedValue: size.side)
        }

        private var isFilled: Bool { value == .checked || value == .indeterminate }

        private var boxColor: Color {
            value == .error ? DesignSystem.Color.iconStatusError : DesignSystem.Color.iconPrimary
        }

        var body: some View {
            ZStack {
                tinted(SelectionControlGlyph.boxRegular, color: boxColor)

                tinted(SelectionControlGlyph.boxFilled, color: DesignSystem.Color.iconPrimary)
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
                case .unchecked, .error:
                    EmptyView()
                case .checked:
                    tinted(SelectionControlGlyph.checkmark, color: DesignSystem.Color.iconInverse)
                        .transition(Animations.markTransition)
                case .indeterminate:
                    tinted(SelectionControlGlyph.indeterminate, color: DesignSystem.Color.iconInverse)
                        .transition(Animations.markTransition)
                }
            }
            .animation(Animations.mark, value: value)
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

private extension Checkbox.CheckboxMark {
    enum Metrics {
        static let markInScale: CGFloat = 0.5
    }

    enum Animations {
        static let fill = Animation.easeInOut(duration: 0.15)
        static let mark = Animation.spring(response: 0.35, dampingFraction: 0.5)

        static let markTransition: AnyTransition = .scale(scale: Metrics.markInScale).combined(with: .opacity)
    }
}
