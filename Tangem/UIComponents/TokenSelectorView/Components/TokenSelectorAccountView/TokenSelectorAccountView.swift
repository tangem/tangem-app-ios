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

    @Environment(\.tokenSelectorShowsSeparators) private var showsSeparators
    @Environment(\.tokenSelectorHidesWalletNameHeader) private var hidesWalletNameHeader

    private var hidesHeader: Bool {
        guard hidesWalletNameHeader, case .wallet = viewModel.header else { return false }
        return true
    }

    private var backgroundColor: Color {
        if FeatureProvider.isAvailable(.redesign) {
            return Color.Tangem.Surface.level3
        }
        return Colors.Background.action
    }

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
            if !hidesHeader {
                TokenSelectorAccountHeaderView(header: viewModel.header)
            }
        }
        .separatorStyle(showsSeparators ? .minimum : .none)
        .backgroundColor(backgroundColor)
    }
}
