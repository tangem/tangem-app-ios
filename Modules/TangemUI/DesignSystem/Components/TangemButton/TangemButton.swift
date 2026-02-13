//
//  TangemButton.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUIUtils
import TangemAssets

public struct TangemButton: View, Setupable {
    private var content: Content
    private var horizontalLayout: HorizontalLayout = .intrinsic
    private var cornerStyle: CornerStyle = .default
    private var styleType: StyleType = .primary
    private var buttonState: ButtonState = .normal

    private var size: Size = .x10 {
        didSet {
            _iconSize = .init(wrappedValue: oldValue.iconSize, relativeTo: oldValue.textStyle)
        }
    }

    private let action: () -> Void

    @ScaledMetric
    private var iconSize: CGFloat

    public init(
        content: Content,
        action: @escaping () -> Void
    ) {
        self.content = content
        self.action = action

        _iconSize = .init(
            wrappedValue: size.iconSize,
            relativeTo: size.textStyle
        )
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
        ))
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

public extension TangemButton {
    func setButtonState(isLoading: Bool, isDisabled: Bool = false) -> Self {
        map { $0.buttonState = .from(isLoading: isLoading, isEnabled: !isDisabled) }
    }

    func setHorizontalLayout(_ horizontalLayout: HorizontalLayout) -> Self {
        map { $0.horizontalLayout = horizontalLayout }
    }

    func setCornerStyle(_ cornerStyle: CornerStyle) -> Self {
        map { $0.cornerStyle = cornerStyle }
    }

    func setStyleType(_ styleType: StyleType) -> Self {
        map { $0.styleType = styleType }
    }

    func setSize(_ size: Size) -> Self {
        map { $0.size = size }
    }
}
