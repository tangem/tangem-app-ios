//
//  CircleButton.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils
import TangemAccessibilityIdentifiers

public struct CircleButton: View {
    private let content: Content
    private let action: () -> Void

    private var disabled: Bool = false
    private var isLoading: Bool = false
    private var style: Style = .secondary
    private var size: Size = .small

    public init(title: String, action: @escaping () -> Void) {
        content = .title(title: title)
        self.action = action
    }

    public init(image: ImageType, action: @escaping () -> Void) {
        content = .icon(image)
        self.action = action
    }

    public init(content: Content, action: @escaping () -> Void) {
        self.content = content
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            contentView
                .padding(.horizontal, size.contentPaddings(content: content).horizontal)
                .padding(.vertical, size.contentPaddings(content: content).vertical)
                .background {
                    Capsule()
                        .fill(style.background(isDisabled: disabled || isLoading))
                }
        }
        .disabled(disabled || isLoading)
    }

    public var contentView: some View {
        ZStack {
            // Keep original content to maintain size
            originalContent
                .opacity(isLoading ? 0 : 1)

            if isLoading {
                ProgressView()
                    // Loading spinner should use non-disabled color since it indicates activity.
                    .progressViewStyle(CircularProgressViewStyle(tint: style.iconColor(isDisabled: false)))
                    .frame(width: size.iconSize, height: size.iconSize)
            }
        }
    }

    @ViewBuilder
    private var originalContent: some View {
        switch content {
        case .title(.none, let string):
            title(string: string)

        case .title(.leading(let imageType), let string):
            HStack(alignment: .center, spacing: .zero) {
                icon(imageType: imageType)

                title(string: string)
            }

        case .title(.trailing(let imageType), let string):
            HStack(alignment: .center, spacing: .zero) {
                title(string: string)

                icon(imageType: imageType)
            }

        case .icon(let imageType):
            icon(imageType: imageType)
        }
    }

    @ViewBuilder
    public func icon(imageType: ImageType) -> some View {
        imageType.image
            .resizable()
            .renderingMode(.template)
            .frame(width: size.iconSize, height: size.iconSize)
            .foregroundStyle(style.iconColor(isDisabled: disabled))
    }

    @ViewBuilder
    public func title(string: String) -> some View {
        Text(.init(string))
            .style(size.textFont, color: style.textColor(isDisabled: disabled))
            // We use the vertical padding to fit the design text container
            .padding(.vertical, size.titleVerticalPadding)
            .padding(.horizontal, 4)
    }
}

// MARK: - Setupable

extension CircleButton: Setupable {
    public func disabled(_ disabled: Bool) -> Self {
        map { $0.disabled = disabled }
    }

    public func loading(_ isLoading: Bool) -> Self {
        map { $0.isLoading = isLoading }
    }

    public func style(_ style: Style) -> Self {
        map { $0.style = style }
    }

    public func size(_ size: Size) -> Self {
        map { $0.size = size }
    }
}

public extension CircleButton {
    enum Content {
        case icon(ImageType)
        case title(icon: IconAlignment? = .none, title: String)
    }

    enum IconAlignment {
        case leading(ImageType)
        case trailing(ImageType)
    }

    enum Size {
        case small
        case medium
        case large

        var textFont: Font {
            switch self {
            case .small: Fonts.Bold.footnote
            case .medium: Fonts.Bold.subheadline
            case .large: Fonts.Bold.body
            }
        }

        var titleVerticalPadding: CGFloat {
            switch self {
            case .small: 2
            case .medium, .large: 0
            }
        }

        var iconSize: CGFloat {
            switch self {
            case .small, .medium: 20
            case .large: 24
            }
        }

        func contentPaddings(content: Content) -> (horizontal: CGFloat, vertical: CGFloat) {
            switch (self, content) {
            case (.small, .icon): (horizontal: 4, vertical: 4)
            case (.medium, .icon): (horizontal: 8, vertical: 8)
            case (.large, .icon): (horizontal: 14, vertical: 14)
            case (.small, _): (horizontal: 6, vertical: 4)
            case (.medium, _): (horizontal: 8, vertical: 8)
            case (.large, _): (horizontal: 16, vertical: 14)
            }
        }
    }

    enum Style {
        case primary
        case secondary

        func textColor(isDisabled: Bool) -> Color {
            switch self {
            case .primary: isDisabled ? Colors.Text.disabled : Colors.Text.primary2
            case .secondary: isDisabled ? Colors.Text.disabled : Colors.Text.primary1
            }
        }

        func iconColor(isDisabled: Bool) -> Color {
            if isDisabled {
                return Colors.Icon.inactive
            }

            return switch self {
            case .primary: Colors.Icon.primary2
            case .secondary: Colors.Icon.informative
            }
        }

        func background(isDisabled: Bool) -> Color {
            switch self {
            case .primary: isDisabled ? Colors.Button.disabled : Colors.Button.primary
            case .secondary: isDisabled ? Colors.Button.disabled : Colors.Button.secondary
            }
        }
    }
}

// MARK: - Types

public extension CircleButton {
    static func close(action: @escaping () -> Void) -> CircleButton {
        CircleButton(content: .icon(Assets.Glyphs.cross20ButtonNew), action: action)
    }

    static func back(action: @escaping () -> Void) -> some View {
        CircleButton(content: .icon(Assets.Glyphs.chevron20LeftButtonNew), action: action)
            .accessibilityIdentifier(CommonUIAccessibilityIdentifiers.circleButton)
    }
}
