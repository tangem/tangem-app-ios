//
//  TokenItemEarnBadgeView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemAccessibilityIdentifiers
import TangemLocalization

struct TokenItemEarnBadgeView: View {
    let apy: String

    private var background: some View {
        RoundedRectangle(cornerRadius: 4, style: .continuous).fill(Colors.Text.accent.opacity(0.1))
    }

    var body: some View {
        HStack(spacing: 6) {
            Text(Localization.yieldModuleEarnBadge(apy))
                .style(Fonts.BoldStatic.caption2, color: Colors.Text.accent)
                .fixedSize(horizontal: true, vertical: false)
                .accessibilityIdentifier(MainAccessibilityIdentifiers.tokenItemEarnBadge)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(background)
        }
    }
}
