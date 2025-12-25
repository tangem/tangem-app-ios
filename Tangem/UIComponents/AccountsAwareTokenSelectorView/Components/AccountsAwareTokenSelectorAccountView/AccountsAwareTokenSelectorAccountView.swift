//
//  AccountsAwareTokenSelectorAccountView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemAccounts

struct AccountsAwareTokenSelectorAccountView: View {
    @ObservedObject var viewModel: AccountsAwareTokenSelectorAccountViewModel

    var body: some View {
        GroupedSection(viewModel.items) { item in
            AccountsAwareTokenSelectorItemView(viewModel: item)
        } header: {
            AccountsAwareTokenSelectorAccountHeaderView(header: viewModel.header)
        }
        .backgroundColor(Colors.Background.action)
    }
}
