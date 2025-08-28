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

// [REDACTED_TODO_COMMENT]
struct TokenItemEarnBadgeView: View {
    let percent: String

    private var background: some View {
        RoundedRectangle(cornerRadius: 4, style: .continuous).fill(Colors.Text.accent.opacity(0.1))
    }

    var body: some View {
        HStack(spacing: 6) {
            // [REDACTED_TODO_COMMENT]
            Text("Earn \(percent)%")
                .style(Fonts.BoldStatic.caption2, color: Colors.Text.accent)
                .fixedSize(horizontal: true, vertical: false)
                .accessibilityIdentifier(MainAccessibilityIdentifiers.tokenItemEarnBadge)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(background)
        }
    }
}
