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

public struct CircleButton: View {
    private let image: ImageType
    private let action: () -> Void

    private var disabled: Bool = false
    private var style: Style = .secondary
    private var size: Size = .small

    public init(image: ImageType, action: @escaping () -> Void) {
        self.image = image
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            image.image
                .resizable()
                .renderingMode(.template)
                .frame(width: size.iconSize, height: size.iconSize)
                .foregroundStyle(style.iconColor(isDisabled: disabled))
                .padding(size.iconPadding)
                .background {
                    Circle()
                        .fill(style.background(isDisabled: disabled))
                }
        }
        .disabled(disabled)
    }
}

// MARK: - Setupable

extension CircleButton: Setupable {
    public func disabled(_ disabled: Bool) -> Self {
        map { $0.disabled = disabled }
    }

    public func style(_ style: Style) -> Self {
        map { $0.style = style }
    }

    public func size(_ size: Size) -> Self {
        map { $0.size = size }
    }
}

public extension CircleButton {
    enum Size {
        case small
        case medium
        case large

        var iconSize: CGFloat {
            switch self {
            case .small, .medium: 20
            case .large: 24
            }
        }

        var iconPadding: CGFloat {
            switch self {
            case .small: 4
            case .medium: 8
            case .large: 14
            }
        }
    }

    enum Style {
        case primary
        case secondary

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
        CircleButton(image: Assets.Glyphs.cross20ButtonNew, action: action)
    }

    static func back(action: @escaping () -> Void) -> some View {
        CircleButton(image: Assets.Glyphs.chevron20LeftButtonNew, action: action)
    }
}
