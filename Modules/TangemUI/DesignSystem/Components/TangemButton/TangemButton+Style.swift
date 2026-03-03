//
//  TangemButton+Style.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

extension TangemButton {
    struct Style: ButtonStyle {
        let size: Size
        let horizontalLayout: HorizontalLayout
        let state: ButtonState
        let style: StyleType
        let content: Content
        let cornerStyle: CornerStyle
        let cornerRadius: CGFloat

        @ScaledMetric
        private var horizontalInset: CGFloat

        @ScaledMetric
        private var iconSize: CGFloat

        init(
            size: Size,
            horizontalLayout: HorizontalLayout,
            state: ButtonState,
            style: StyleType,
            content: Content,
            cornerStyle: CornerStyle,
            cornerRadius: CGFloat,
            iconSize: ScaledMetric<CGFloat>
        ) {
            self.size = size
            self.horizontalLayout = horizontalLayout
            self.state = state
            self.style = style
            self.content = content
            self.cornerStyle = cornerStyle
            self.cornerRadius = cornerRadius
            _iconSize = iconSize
            _horizontalInset = .init(
                wrappedValue: size.horizontalInsets,
                relativeTo: size.textStyle
            )
        }

        public func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .hidden(state.isLoading)
                .padding(.horizontal, makeHorizontalInsets())
                .frame(height: size.height)
                .frame(maxWidth: horizontalLayout.maxWidth)
                .background(makeBackgroundColor(), in: buttonShape)
                .overlay { buttonShape.stroke(style.strokeColor, lineWidth: 1) }
                .foregroundStyle(makeForegroundColor())
                .overlay { buttonShape.fill(makeOverlayColor(isPressed: configuration.isPressed)) }
                .overlay {
                    if state.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressStyle(
                                size: size.iconSize,
                                color: style.foregroundColor
                            ))
                    }
                }
        }

        @ShapeBuilder
        private var buttonShape: AnyInsettableShape {
            if case .icon = content, cornerStyle == .rounded, horizontalLayout == .intrinsic {
                Circle()
            } else {
                switch cornerStyle {
                case .rectangular:
                    RoundedRectangle(cornerRadius: cornerRadius)
                case .rounded:
                    Capsule()
                }
            }
        }

        private func makeHorizontalInsets() -> CGFloat {
            switch content {
            case .text, .combined:
                return horizontalInset
            case .icon:
                return (size.height - iconSize) / 2
            }
        }

        private func makeBackgroundColor() -> Color {
            if state.isDisabled {
                return style.colorScheme.disabledBackground
            }

            return style.colorScheme.background
        }

        private func makeOverlayColor(isPressed: Bool) -> Color {
            if state.isLoading {
                return style.colorScheme.loadingOverlay
            }

            if isPressed {
                return style.colorScheme.pressedOverlay
            }

            return .clear
        }

        private func makeForegroundColor() -> Color {
            switch state {
            case .normal, .loading:
                return style.foregroundColor
            case .disabled:
                return .disabledForeground
            }
        }
    }
}

private extension Color {
    static let disabledForeground: Color = .Tangem.Text.Status.disabled
}
