//
//  SendTokenHeaderView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemAccounts
import TangemLocalization

struct SendTokenHeaderView: View {
    let header: SendTokenHeader

    var body: some View {
        switch header {
        case .action(let name):
            Text(.init(name))
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
        case .wallet(let name):
            Text(.init(Localization.commonFromWalletName(name)))
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
        case .account(let name, let icon):
            HStack(spacing: 6) {
                Text(.init(Localization.commonFrom))
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                HStack(spacing: 4) {
                    AccountIconView(data: icon)
                        .settings(.smallSized)

                    Text(name)
                        .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
                }
            }
        }
    }
}
