//
//  AccountRowView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemAccounts
import Combine

struct AccountRowView<Trailing: View>: View {
    @StateObject private var viewModel: AccountRowViewModel
    private let trailing: Trailing

    init(
        input: AccountRowViewModel.Input,
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        _viewModel = StateObject(wrappedValue: AccountRowViewModel(input: input))
        self.trailing = trailing()
    }

    var body: some View {
        HStack(spacing: 12) {
            AccountIconView(data: viewModel.iconData)

            VStack(alignment: .leading, spacing: 0) {
                Text(viewModel.name)
                    .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

                HStack(spacing: 4) {
                    Text(viewModel.subtitle)
                        .style(Constants.subtitleFont, color: Constants.subtitleColor)

                    if let balanceState = viewModel.balanceState {
                        Text(AppConstants.dotSign)
                            .style(Constants.subtitleFont, color: Constants.subtitleColor)

                        LoadableTokenBalanceView(
                            state: balanceState,
                            style: .init(font: Constants.subtitleFont, textColor: Constants.subtitleColor),
                            loader: .init(size: CGSize(width: 40, height: 12))
                        )
                    }
                }
            }
            .frame(alignment: .leading)

            Spacer()

            trailing
        }
    }
}

// MARK: - Default Empty Trailing

extension AccountRowView where Trailing == EmptyView {
    init(input: AccountRowViewModel.Input) {
        _viewModel = StateObject(wrappedValue: AccountRowViewModel(input: input))
        trailing = EmptyView()
    }
}

// MARK: - Constants

private enum Constants {
    static let subtitleColor = Colors.Text.tertiary
    static let subtitleFont = Fonts.Regular.caption1
}
