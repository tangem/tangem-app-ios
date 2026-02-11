//
//  ActionButtonsSwapHeaderView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization

struct ActionButtonsSwapHeaderView: View {
    let headerType: ExpressCurrencyHeaderType
    let remove: (() -> Void)?

    var body: some View {
        HStack(spacing: .zero) {
            ExpressCurrencyDefaultHeaderView(headerType: headerType)

            Spacer()

            if let remove {
                Button(action: remove) {
                    Text(Localization.manageTokensRemove)
                        .style(Fonts.Regular.footnote, color: Colors.Text.accent)
                }
            }
        }
        .padding(.vertical, 8)
    }
}
