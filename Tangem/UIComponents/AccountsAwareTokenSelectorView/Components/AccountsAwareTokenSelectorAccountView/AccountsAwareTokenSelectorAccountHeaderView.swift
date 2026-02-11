//
//  AccountsAwareTokenSelectorAccountHeaderView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccounts
import TangemAssets

struct AccountsAwareTokenSelectorAccountHeaderView: View {
    let header: AccountsAwareTokenSelectorAccountViewModel.HeaderType

    var body: some View {
        content
            .padding(.top, 12)
            .padding(.bottom, 8)
    }

    @ViewBuilder
    var content: some View {
        switch header {
        case .account(let icon, let name):
            AccountInlineHeaderView(iconData: icon, name: name)
        case .wallet(let name):
            Text(name)
                .style(Fonts.Bold.footnote, color: Colors.Text.primary1)
        }
    }
}
