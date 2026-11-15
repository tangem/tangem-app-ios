//
//  ActionMessage.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

public struct ActionMessage: View, Setupable {
    private let text: String
    private let icon: ImageType
    private let action: () -> Void
    private var variant: Variant = .neutral

    @ScaledMetric private var iconSize: CGFloat = 16
    @ScaledMetric private var chevronSize: CGFloat = 12
    @ScaledMetric private var spacing: CGFloat = 8
    @ScaledMetric private var horizontalPadding: CGFloat = 12
    @ScaledMetric private var verticalPadding: CGFloat = 8

    public init(_ text: String, icon: ImageType, action: @escaping () -> Void) {
        self.text = text
        self.icon = icon
        self.action = action
    }

    public var body: some View {
        SwiftUI.Button(action: action) {
            HStack(spacing: spacing) {
                glyph(icon, size: iconSize)

                Text(text)
                    .style(DesignSystem.Font.captionMediumToken, color: variant.palette.text)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)

                glyph(DesignSystem.Icons.ChevronRight.regular12, size: chevronSize)
                    .flipsForRightToLeftLayoutDirection(true)
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
        }
        .buttonStyle(Style(background: variant.palette.background))
    }

    private func glyph(_ image: ImageType, size: CGFloat) -> some View {
        image.image
            .renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .foregroundStyle(variant.palette.icon)
            .accessibilityHidden(true)
    }
}

// MARK: - Setupable

public extension ActionMessage {
    func variant(_ variant: Variant) -> Self {
        map { $0.variant = variant }
    }
}

// MARK: - Public Type

public enum ActionMessageVariant: Sendable, Hashable, CaseIterable {
    case neutral
    case success
    case error
    case warning
    case info
}

public extension ActionMessage {
    typealias Variant = ActionMessageVariant
}

// MARK: - Palette

private struct ActionMessagePalette {
    let background: Color
    let text: Color
    let icon: Color
}

private extension ActionMessageVariant {
    var palette: ActionMessagePalette {
        switch self {
        case .neutral:
            ActionMessagePalette(
                background: DesignSystem.Color.bgTertiary,
                text: DesignSystem.Color.textPrimary,
                icon: DesignSystem.Color.iconSecondary
            )
        case .success:
            ActionMessagePalette(
                background: DesignSystem.Color.bgStatusSuccessSubtle,
                text: DesignSystem.Color.textStatusSuccess,
                icon: DesignSystem.Color.iconStatusSuccess
            )
        case .error:
            ActionMessagePalette(
                background: DesignSystem.Color.bgStatusErrorSubtle,
                text: DesignSystem.Color.textStatusError,
                icon: DesignSystem.Color.iconStatusError
            )
        case .warning:
            ActionMessagePalette(
                background: DesignSystem.Color.bgStatusWarningSubtle,
                text: DesignSystem.Color.textStatusWarning,
                icon: DesignSystem.Color.iconStatusWarning
            )
        case .info:
            ActionMessagePalette(
                background: DesignSystem.Color.bgStatusInfoSubtle,
                text: DesignSystem.Color.textStatusInfo,
                icon: DesignSystem.Color.iconStatusInfo
            )
        }
    }
}
