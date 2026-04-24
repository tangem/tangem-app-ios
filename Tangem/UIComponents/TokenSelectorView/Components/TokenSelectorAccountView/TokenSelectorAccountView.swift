//
//  TokenSelectorAccountView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemAccounts

struct TokenSelectorAccountView: View {
    @ObservedObject var viewModel: TokenSelectorAccountViewModel

    @ViewBuilder
    var body: some View {
        if let expandableViewModel = viewModel.expandableViewModel {
            if !viewModel.items.isEmpty {
                TokenSelectorExpandableAccountSectionView(
                    expandableViewModel: expandableViewModel,
                    accountViewModel: viewModel
                )
            }
        } else {
            nonExpandableView
        }
    }

    private var nonExpandableView: some View {
        GroupedSection(viewModel.items, isLazy: true) { item in
            TokenSelectorItemView(viewModel: item)
        } header: {
            TokenSelectorAccountHeaderView(header: viewModel.header)
        }
        .backgroundColor(Colors.Background.action)
    }
}
