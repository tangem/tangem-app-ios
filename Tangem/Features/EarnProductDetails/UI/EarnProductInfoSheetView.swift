//
//  EarnProductInfoSheetView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct EarnProductInfoSheetView: View {
    let sheet: EarnProductDetails.InfoSheet

    var body: some View {
        switch sheet.content {
        case .text(let text):
            Text(text)
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
        case .levels(let levels):
            VStack(spacing: 0) {
                ForEach(indexed: levels, id: \.1) { index, level in
                    Row(title: level.title, subtitle: level.text)
                        .subtitleLineLimit(nil)
                        .showDivider(index < levels.count - 1)
                }
            }
        }
    }
}

// MARK: - Previews

#Preview {
    let details = EarnProductDetails.preview

    VStack(spacing: 24) {
        EarnProductInfoSheetView(sheet: details.risk.info)
        EarnProductInfoSheetView(sheet: details.withdrawals.info)
    }
    .background(DesignSystem.Color.bgPrimary)
}
