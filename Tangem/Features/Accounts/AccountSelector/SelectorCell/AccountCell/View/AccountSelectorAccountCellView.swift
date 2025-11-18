//
//  AccountSelectorAccountCellView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemAccounts

struct AccountSelectorAccountCellView: View {
    @StateObject private var viewModel: AccountSelectorAccountCellViewModel

    init(accountModel: AccountSelectorAccountItem) {
        _viewModel = StateObject(wrappedValue: AccountSelectorAccountCellViewModel(accountModel: accountModel))
    }

    var body: some View {
        content
            .lineLimit(1)
            .padding(.init(top: 12, leading: 14, bottom: 12, trailing: 14))
            .contentShape(.rect)
            .background(Colors.Background.action)
            .cornerRadius(14, corners: .allCorners)
    }

    private var content: some View {
        HStack(spacing: 12) {
            AccountIconView(
                data: AccountIconView.ViewData(
                    backgroundColor: AccountModelUtils.UI.iconColor(from: viewModel.accountModel.icon.color),
                    nameMode: AccountModelUtils.UI.nameMode(
                        from: viewModel.accountModel.icon.name,
                        accountName: viewModel.accountModel.name
                    )
                )
            )

            VStack(alignment: .leading, spacing: 6) {
                Text(viewModel.accountModel.name)
                    .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

                Text(viewModel.accountModel.tokensCount)
                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if viewModel.fiatBalanceState != .empty {
                LoadableTokenBalanceView(
                    state: viewModel.fiatBalanceState,
                    style: .init(font: Fonts.Regular.subheadline, textColor: Colors.Text.primary1),
                    loader: .init(size: CGSize(width: 40, height: 12))
                )
            }
        }
    }
}
