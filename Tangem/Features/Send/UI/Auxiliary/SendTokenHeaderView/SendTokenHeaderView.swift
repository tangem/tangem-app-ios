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
            Text(.init(Localization.sendFromWallet(name)))
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
        case .account(let name, let icon):
            HStack(spacing: 6) {
                AccountIconView(data: icon)
                    .settings(.smallSized)

                Text(name)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
            }
        }
    }
}
