//
//  CapsuleButton.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

public struct CapsuleButton: View {
    private let icon: Icon?
    private let title: String
    private let action: () -> Void

    private var disabled: Bool = false
    private var isLoading: Bool = false
    private var style: Style = .secondary
    private var size: Size = .small

    public init(icon: Icon? = nil, title: String, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            contentView
                .padding(.horizontal, size.contentPaddings.horizontal)
                .padding(.vertical, size.contentPaddings.vertical)
                .background {
                    Capsule()
                        .fill(style.background(isDisabled: disabled || isLoading))
                }
        }
        .disabled(disabled || isLoading)
    }

    private var contentView: some View {
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
        switch icon {
        case .none:
            titleView

        case .leading(let iconAsset):
            HStack(alignment: .center, spacing: .zero) {
                iconView(with: iconAsset)
                titleView
            }

        case .trailing(let iconAsset):
            HStack(alignment: .center, spacing: .zero) {
                titleView
                iconView(with: iconAsset)
            }
        }
    }

    private func iconView(with imageType: ImageType) -> some View {
        imageType.image
            .resizable()
            .renderingMode(.template)
            .frame(width: size.iconSize, height: size.iconSize)
            .foregroundStyle(style.iconColor(isDisabled: disabled))
    }

    private var titleView: some View {
        Text(.init(title))
            .style(size.textFont, color: style.textColor(isDisabled: disabled))
            // We use the vertical padding to fit the design text container
            .padding(.vertical, size.titleVerticalPadding)
            .padding(.horizontal, 4)
    }
}

// MARK: - Setupable

extension CapsuleButton: Setupable {
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

public extension CapsuleButton {
    enum Icon {
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

        var contentPaddings: (horizontal: CGFloat, vertical: CGFloat) {
            switch self {
            case .small: (horizontal: 6, vertical: 4)
            case .medium: (horizontal: 8, vertical: 8)
            case .large: (horizontal: 16, vertical: 14)
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
