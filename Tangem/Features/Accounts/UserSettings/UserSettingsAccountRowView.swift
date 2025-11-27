//
//  UserSettingsAccountRowView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemAccounts

struct UserSettingsAccountRowView<Trailing: View>: View {
    @ObservedObject var viewModel: UserSettingsAccountRowViewModel

    @ScaledMetric
    private var balanceLoaderHeight: CGFloat = 12

    @ScaledMetric
    private var balanceLoaderWidth: CGFloat = 40

    let trailing: Trailing

    var body: some View {
        Button(action: viewModel.tap) {
            HStack(spacing: 12) {
                AccountIconView(data: viewModel.iconData)

                VStack(alignment: .leading, spacing: 0) {
                    Text(viewModel.name)
                        .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

                    subtitleView
                        .style(Constants.subtitleFont, color: Constants.subtitleColor)
                }
                .frame(alignment: .leading)

                Spacer()

                trailing
            }
        }
    }

    @ViewBuilder
    private var subtitleView: some View {
        switch viewModel.subtitleState {
        case .descriptionOnly(let text):
            Text(text)

        case .descriptionWithBalance(let text, let balance):
            HStack(spacing: 4) {
                Text(text)
                Text(AppConstants.dotSign)
                balanceView(state: balance)
            }

        case .balanceOnly(let balance):
            balanceView(state: balance)

        case .none:
            EmptyView()
        }
    }

    private func balanceView(state: LoadableTokenBalanceView.State) -> some View {
        LoadableTokenBalanceView(
            state: state,
            style: .init(font: Constants.subtitleFont, textColor: Constants.subtitleColor),
            loader: .init(size: CGSize(width: balanceLoaderWidth, height: balanceLoaderHeight))
        )
    }
}

// MARK: - Constants

private enum Constants {
    static let subtitleColor = Colors.Text.tertiary
    static let subtitleFont = Fonts.Regular.caption1
}
