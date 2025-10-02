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

struct AccountSelectorAccountCellView: View {
    @StateObject private var viewModel: AccountSelectorAccountCellViewModel

    init(accountModel: AccountSelectorAccountItem) {
        _viewModel = StateObject(wrappedValue: AccountSelectorAccountCellViewModel(accountModel: accountModel))
    }

    var body: some View {
        content
            .lineLimit(1)
            .padding(14)
            .contentShape(.rect)
    }

    private var content: some View {
        HStack(spacing: 12) {
            accountIcon(viewModel.accountModel.icon)
                .frame(width: 36, height: 36)

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

    private func accountIcon(_ icon: AccountModel.Icon) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .foregroundColor(AccountModelUtils.UI.iconColor(from: icon.color))

            AccountModelUtils.UI.iconImage(from: icon.name)
                .font(.system(size: 18, weight: .medium))
        }
    }
}
