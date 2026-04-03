//
//  MainQRScanTokenSelectorWalletItemView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct MainQRScanTokenSelectorWalletItemView: View {
    @ObservedObject var viewModel: AccountsAwareTokenSelectorWalletItemViewModel
    let isAccountsMode: Bool
    let accountsModeSingleWalletHeader: AccountsAwareTokenSelectorAccountViewModel.HeaderType?

    @ViewBuilder
    var body: some View {
        if viewModel.contentVisibility?.isVisible == true {
            if isAccountsMode {
                accountsModeContent
            } else {
                walletsModeContent
            }
        }
    }

    @ViewBuilder
    private var walletsModeContent: some View {
        switch viewModel.viewType {
        case .wallet(let accountViewModel):
            if accountViewModel.hasCompatibleItems {
                MainQRScanTokenSelectorAccountSectionView(viewModel: accountViewModel)
            }

        case .accounts(_, let accounts):
            let compatibleAccounts = accounts.filter(\.hasCompatibleItems)

            ForEach(Array(compatibleAccounts.enumerated()), id: \.element.id) { index, account in
                MainQRScanTokenSelectorAccountSectionView(viewModel: account)
                    .padding(.bottom, index == compatibleAccounts.count - 1 ? 0.0 : Constants.accountsListVerticalSpacing)
            }
        }
    }

    @ViewBuilder
    private var accountsModeContent: some View {
        switch viewModel.viewType {
        case .wallet(let accountViewModel):
            if accountViewModel.hasCompatibleItems {
                accountsModeWalletContent(
                    walletName: accountViewModel.walletName,
                    accounts: [accountViewModel],
                    accountHeaderOverride: accountsModeSingleWalletHeader
                )
            }

        case .accounts(let walletName, let accounts):
            let compatibleAccounts = accounts.filter(\.hasCompatibleItems)
            accountsModeWalletContent(
                walletName: walletName,
                accounts: compatibleAccounts,
                accountHeaderOverride: nil
            )
        }
    }

    @ViewBuilder
    private func accountsModeWalletContent(
        walletName: String,
        accounts: [AccountsAwareTokenSelectorAccountViewModel],
        accountHeaderOverride: AccountsAwareTokenSelectorAccountViewModel.HeaderType?
    ) -> some View {
        if !accounts.isEmpty {
            LazyVStack(spacing: 0.0) {
                MainQRScanTokenSelectorWalletHeaderView(
                    walletName: walletName,
                    isOpen: viewModel.isOpen,
                    toggleAction: { viewModel.toggleIsOpen() }
                )
                .padding(.bottom, Constants.accountsListVerticalSpacing)
                .background(Colors.Background.tertiary)
                .zIndex(100.0)

                if viewModel.isOpen {
                    ForEach(Array(accounts.enumerated()), id: \.element.id) { index, account in
                        MainQRScanTokenSelectorAccountSectionView(
                            viewModel: account,
                            headerOverride: accountHeaderOverride
                        )
                        .padding(.bottom, index == accounts.count - 1 ? 0.0 : Constants.accountsListVerticalSpacing)
                    }
                    .zIndex(50.0)
                    .transition(.move(edge: .top))
                } else {
                    Separator(color: Colors.Stroke.primary)
                        .transition(.opacity)
                }
            }
            .clipped()
        }
    }
}

private extension MainQRScanTokenSelectorWalletItemView {
    enum Constants {
        static let accountsListVerticalSpacing = 8.0
    }
}
