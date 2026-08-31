//
//  BadgeView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct BadgeView: View {
    let item: Item

    private var titleColor: Color {
        switch item.style {
        case .accent:
            DesignSystem.Color.textStatusInfo
        case .secondary:
            DesignSystem.Color.textSecondary
        case .warning:
            DesignSystem.Color.textStatusWarning
        case .error:
            DesignSystem.Color.textStatusError
        }
    }

    private var bgColor: Color {
        switch item.style {
        case .accent:
            DesignSystem.Color.bgStatusInfoSubtle
        case .secondary:
            DesignSystem.Color.bgOpaqueSecondary
        case .warning:
            DesignSystem.Color.bgStatusWarningSubtle
        case .error:
            DesignSystem.Color.bgStatusErrorSubtle
        }
    }

    var body: some View {
        Text(item.title)
            .style(DesignSystem.Font.captionMediumToken, color: titleColor)
            .padding(.vertical, 4)
            .padding(.horizontal, 12)
            .background(bgColor)
            .clipShape(Capsule())
    }
}

// MARK: - Types

extension BadgeView {
    struct Item: Hashable {
        let title: String
        let style: Style
    }

    enum Style {
        case accent
        case secondary
        case warning
        case error
    }
}
