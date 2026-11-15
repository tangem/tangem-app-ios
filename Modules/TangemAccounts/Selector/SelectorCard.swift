//
//  SelectorCard.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct SelectorCard<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(DesignSystem.Color.bgTransparentOnMaterialPrimary)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

struct SelectorLockedSubtitle: View {
    var body: some View {
        HStack(spacing: 4) {
            Text(Localization.commonLocked)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)

            DesignSystem.Icons.Lock.regular12.image
                .renderingMode(.template)
                .foregroundStyle(DesignSystem.Color.iconSecondary)
        }
    }
}

struct SelectorUnavailableBadge: View {
    let label: String

    var body: some View {
        Badge(label: label, accessibilityLabel: nil)
            .size(.x6)
            .variant(.tinted)
            .appearance(.neutral)
    }
}
