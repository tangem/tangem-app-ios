//
//  TokenRowLeaves.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct TokenRowTitleText: View {
    private let text: String
    private let isDimmed: Bool
    private let accessibilityIdentifier: String?

    init(_ text: String, isDimmed: Bool = false, accessibilityIdentifier: String? = nil) {
        self.text = text
        self.isDimmed = isDimmed
        self.accessibilityIdentifier = accessibilityIdentifier
    }

    var body: some View {
        Text(text)
            .style(
                DesignSystem.Font.bodyMediumToken,
                color: isDimmed ? DesignSystem.Color.textTertiary : DesignSystem.Color.textPrimary
            )
            .lineLimit(1)
            .truncationMode(.tail)
            .accessibilityIdentifier(accessibilityIdentifier)
    }
}

struct TokenRowCaptionText: View {
    private let text: String
    private let accessibilityIdentifier: String?

    init(_ text: String, accessibilityIdentifier: String? = nil) {
        self.text = text
        self.accessibilityIdentifier = accessibilityIdentifier
    }

    var body: some View {
        Text(text)
            .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
            .lineLimit(1)
            .truncationMode(.tail)
            .accessibilityIdentifier(accessibilityIdentifier)
    }
}

struct TokenRowTokenIcon: View {
    private let icon: TokenIconInfo
    private let isGrayscale: Bool
    private let indicatorColor: Color?
    private let accessibilityIdentifier: String?

    init(
        _ icon: TokenIconInfo,
        isGrayscale: Bool = false,
        indicatorColor: Color? = nil,
        accessibilityIdentifier: String? = nil
    ) {
        self.icon = icon
        self.isGrayscale = isGrayscale
        self.indicatorColor = indicatorColor
        self.accessibilityIdentifier = accessibilityIdentifier
    }

    var body: some View {
        tokenIcon
            .grayscale(isGrayscale)
            .accessibilityIdentifier(accessibilityIdentifier)
    }

    private var tokenIcon: TokenIconV2 {
        let tokenIcon = TokenIconV2(tokenIconInfo: icon, size: TokenRowMetrics.iconSize)

        guard let indicatorColor else {
            return tokenIcon
        }

        return tokenIcon.indicatorColor(indicatorColor)
    }
}
