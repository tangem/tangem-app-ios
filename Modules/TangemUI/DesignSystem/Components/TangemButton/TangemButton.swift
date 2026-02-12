//
//  TangemButton.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

public struct TangemButton: View {
    private let content: Content
    private let size: Size
    private let horizontalLayout: HorizontalLayout
    private let cornerStyle: CornerStyle
    private let styleType: StyleType
    private let action: () -> Void

    private var buttonState: ButtonState

    @ScaledMetric
    private var iconSize: CGFloat

    public init(
        content: Content,
        buttonState: ButtonState = .normal,
        size: Size = .x10,
        horizontalLayout: HorizontalLayout = .intrinsic,
        cornerStyle: CornerStyle = .default,
        styleType: StyleType = .primary,
        action: @escaping () -> Void
    ) {
        self.content = content
        self.buttonState = buttonState
        self.size = size
        self.horizontalLayout = horizontalLayout
        self.cornerStyle = cornerStyle
        self.styleType = styleType
        _iconSize = .init(
            wrappedValue: size.iconSize,
            relativeTo: size.textStyle
        )

        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            label
        }
        .buttonStyle(Style(
            size: size,
            horizontalLayout: horizontalLayout,
            state: buttonState,
            style: styleType,
            content: content,
            cornerStyle: cornerStyle,
            cornerRadius: size.cornerRadius,
            iconSize: _iconSize
        )
        )
        .disabled(!buttonState.isNormal)
    }

    @ViewBuilder
    private var label: some View {
        switch content {
        case .text(let text):
            title(for: text)

        case .icon(let icon):
            imageView(from: icon)

        case .combined(let text, let icon, let iconPosition):
            HStack(spacing: SizeUnit.x1.value) {
                switch iconPosition {
                case .left:
                    imageView(from: icon)

                    title(for: text)
                case .right:
                    title(for: text)

                    imageView(from: icon)
                }
            }
        }
    }

    @ViewBuilder
    private func title(for text: AttributedString) -> some View {
        Text(text)
            .font(size.font)
            .lineLimit(1)
    }

    @ViewBuilder
    private func imageView(from icon: Image) -> some View {
        icon
            .resizable()
            .renderingMode(.template)
            .aspectRatio(contentMode: .fit)
            .frame(width: iconSize, height: iconSize)
    }
}
