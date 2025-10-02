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

struct AccountSelectorView: View {
    @ObservedObject var viewModel: AccountSelectorViewModel

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0) {
                switch viewModel.displayMode {
                case .wallets:
                    walletsView
                case .sections:
                    sectionsView
                }

                lockedWalletsView
                    .padding(.top, 20)
            }
            .padding(.init(top: 12, leading: 16, bottom: 16, trailing: 16))
            .animation(.easeInOut(duration: 0.25), value: viewModel.selectedAccount)
        }
    }

    @ViewBuilder
    private func cellSelectionBorder(for cell: AccountSelectorCellModel) -> some View {
        if viewModel.checkItemSelection(for: cell) {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Colors.Text.accent, lineWidth: 1)
        }
    }

    @ViewBuilder
    private func cellDivider(_ index: Int, total: Int) -> some View {
        if index < total - 1 {
            Separator(color: Colors.Stroke.primary, axis: .horizontal)
                .padding(.leading, 62)
                .padding(.trailing, 14)
        }
    }
}

// MARK: Wallets

private extension AccountSelectorView {
    var walletsView: some View {
        ForEach(indexed: viewModel.walletItems.indexed()) { index, wallet in
            ZStack(alignment: .bottom) {
                Button(
                    action: { viewModel.handleViewAction(.selectItem(.wallet(wallet))) },
                    label: { AccountSelectorWalletCellView(walletModel: wallet) }
                )
                .buttonStyle(.plain)

                cellDivider(index, total: viewModel.walletItems.count)

                cellSelectionBorder(for: .wallet(wallet))
            }
        }
    }
}

// MARK: Account Sections

private extension AccountSelectorView {
    func sectionHeader(_ title: String) -> some View {
        Text(title)
            .frame(maxWidth: .infinity, alignment: .leading)
            .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
            .padding(.horizontal, 12)
            .padding(.bottom, 10)
    }

    var sectionsView: some View {
        ForEach(viewModel.accountSections) { section in
            VStack(spacing: 0) {
                if viewModel.accountSections.count > 1 {
                    sectionHeader(section.walletName)
                }

                ForEach(indexed: section.accounts.indexed()) { accountIndex, account in
                    ZStack(alignment: .bottom) {
                        Button(
                            action: { viewModel.handleViewAction(.selectItem(.account(account))) },
                            label: { AccountSelectorAccountCellView(accountModel: account) }
                        )
                        .buttonStyle(.plain)

                        cellDivider(accountIndex, total: section.accounts.count)

                        cellSelectionBorder(for: .account(account))
                    }
                }
            }
            .padding(.bottom, 24)
        }
    }
}

// MARK: Locked Wallets Section

private extension AccountSelectorView {
    @ViewBuilder
    var lockedWalletsView: some View {
        if viewModel.lockedWalletItems.isNotEmpty {
            VStack(spacing: 0) {
                sectionHeader(Localization.commonLockedWallets)

                ForEach(indexed: viewModel.lockedWalletItems.indexed()) { index, wallet in
                    AccountSelectorWalletCellView(walletModel: wallet)

                    cellDivider(index, total: viewModel.lockedWalletItems.count)
                }
            }
        }
    }
}
