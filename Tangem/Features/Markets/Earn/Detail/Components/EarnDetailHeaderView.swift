//
//  EarnDetailHeaderView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct EarnDetailHeaderView: View {
    let headerTitle: String

    var body: some View {
        HStack(alignment: .center, spacing: .zero) {
            Text(headerTitle)
                .lineLimit(1)
                .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)

            Spacer(minLength: 8)
        }
        .padding(.horizontal, Layout.horizontalPadding)
    }
}

extension EarnDetailHeaderView {
    enum Layout {
        static let horizontalPadding: CGFloat = 16.0
    }
}
