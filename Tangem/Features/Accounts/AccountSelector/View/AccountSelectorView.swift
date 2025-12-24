//
//  AccountSelectorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils
import TangemLocalization
import TangemAccounts

struct AccountSelectorView: View {
    @ObservedObject var viewModel: AccountSelectorViewModel

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0) {
                switch viewModel.displayMode {
                case .wallets:
                    walletsView
                case .accounts:
                    accountSectionsView
                }

                lockedWalletsView
                    .padding(.top, 20)
            }
            .padding(.init(top: 12, leading: 16, bottom: 16, trailing: 16))
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .frame(maxWidth: .infinity, alignment: .leading)
            .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
            .padding(.horizontal, 12)
            .padding(.bottom, 10)
    }

    @ViewBuilder
    private func cellSelectionBorder(for cell: AccountSelectorCellModel) -> some View {
        if viewModel.isCellSelected(for: cell) {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Colors.Text.accent, lineWidth: 1)
        }
    }
}

// MARK: Wallets

private extension AccountSelectorView {
    var walletsView: some View {
        VStack(spacing: 6) {
            ForEach(viewModel.walletItems) { wallet in
                walletCell(for: wallet)
            }
        }
    }

    func walletCell(for wallet: AccountSelectorWalletItem) -> some View {
        ZStack {
            Button(
                action: { viewModel.handleViewAction(.selectItem(.wallet(wallet))) },
                label: { AccountSelectorWalletCellView(walletModel: wallet) }
            )
            .buttonStyle(.plain)

            cellSelectionBorder(for: .wallet(wallet))
        }
    }
}

// MARK: Account Sections

private extension AccountSelectorView {
    var accountSectionsView: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.accountsSections) { section in
                accountSectionContent(for: section)
                    .padding(.bottom, 24)
            }
        }
    }

    func accountSectionContent(for section: AccountSelectorMultipleAccountsItem) -> some View {
        VStack(spacing: 0) {
            if viewModel.accountsSections.count > 1 {
                sectionHeader(section.walletName)
            }

            VStack(spacing: 6) {
                ForEach(section.accounts) { entry in
                    accountSectionCell(for: entry)
                }
            }
        }
    }

    func accountSectionCell(for entry: AccountSelectorMultipleAccountsItem.AccountEntry) -> some View {
        ZStack {
            AccountRowButtonView(viewModel: entry.rowViewModel)
                .buttonStyle(.plain)
                .lineLimit(1)
                .padding(.vertical, 12)
                .padding(.horizontal, 14)
                .contentShape(.rect)
                .background(Colors.Background.action)
                .cornerRadius(14, corners: .allCorners)

            cellSelectionBorder(for: .account(entry.item))
        }
    }
}

// MARK: Locked Wallets Section

private extension AccountSelectorView {
    @ViewBuilder
    var lockedWalletsView: some View {
        if viewModel.lockedWalletItems.isNotEmpty {
            VStack(spacing: 6) {
                sectionHeader(Localization.commonLockedWallets)

                ForEach(viewModel.lockedWalletItems) {
                    AccountSelectorWalletCellView(walletModel: $0)
                }
            }
        }
    }
}
