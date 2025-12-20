//
//  AccountsAwareActionButtonsSwapHeaderView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization

struct AccountsAwareActionButtonsSwapHeaderView: View {
    let title: String
    let remove: (() -> Void)?

    var body: some View {
        HStack(spacing: .zero) {
            Text(title)
                .style(Fonts.Regular.footnote, color: Colors.Text.secondary)

            Spacer()

            if let remove {
                Button(action: remove, label: {
                    Text(Localization.manageTokensRemove)
                        .style(Fonts.Regular.footnote, color: Colors.Text.accent)
                })
            }
        }
        .padding(.vertical, 8)
    }
}
