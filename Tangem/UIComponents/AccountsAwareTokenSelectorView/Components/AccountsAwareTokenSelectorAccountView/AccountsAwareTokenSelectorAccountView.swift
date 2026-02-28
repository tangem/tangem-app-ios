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
        VStack(spacing: 0) {
            AccountsAwareTokenSelectorAccountHeaderView(header: viewModel.header)

            LazyVStack(spacing: 0) {
                ForEach(viewModel.items) { item in
                    AccountsAwareTokenSelectorItemView(viewModel: item)
                }
            }
        }
//        .backgroundColor(Colors.Background.action)
    }
}
