//
//  MainQRScanTokenSelectorIncompatibleTokensRow.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct MainQRScanTokenSelectorIncompatibleTokensRow: View {
    let count: Int

    var body: some View {
        HStack(spacing: 8.0) {
            Assets.crossedEyeIcon.image
                .renderingMode(.template)
                .resizable()
                .foregroundColor(Colors.Icon.inactive)
                .frame(width: 16.0, height: 16.0)

            Text(Localization.sendNetworkSelectionHiddenTokens(count))
                .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 12.0)
    }
}
