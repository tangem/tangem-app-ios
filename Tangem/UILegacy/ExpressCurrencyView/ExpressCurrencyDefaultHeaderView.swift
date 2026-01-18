//
//  ExpressCurrencyDefaultHeaderView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import struct TangemAccounts.AccountIconView

struct ExpressCurrencyDefaultHeaderView: View {
    let headerType: ExpressCurrencyHeaderType

    var body: some View {
        switch headerType {
        case .action(let name):
            Text(name)
                .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
        case .wallet(let name):
            Text(name)
                .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
        case .account(let prefix, let name, let icon):
            HStack(spacing: 6) {
                Text(prefix)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                HStack(spacing: 4) {
                    AccountIconView(data: icon)
                        .settings(.extraSmallSized)

                    Text(name)
                        .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
                }
            }
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Action") {
    ExpressCurrencyDefaultHeaderView(headerType: .action(name: "You send"))
}

#Preview("Wallet") {
    ExpressCurrencyDefaultHeaderView(headerType: .wallet(name: "From Main Wallet"))
}

#Preview("Account") {
    ExpressCurrencyDefaultHeaderView(
        headerType: .account(
            prefix: "From",
            name: "Account 1",
            icon: .init(backgroundColor: .blue, nameMode: .letter("A"))
        )
    )
}
#endif // DEBUG
