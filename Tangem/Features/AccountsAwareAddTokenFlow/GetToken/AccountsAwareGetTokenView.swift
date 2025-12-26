//
//  AccountsAwareGetTokenView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

struct AccountsAwareGetTokenView: View {
    @ObservedObject var viewModel: AccountsAwareGetTokenViewModel

    var body: some View {
        VStack(spacing: 0) {
            EntitySummaryView(viewState: viewModel.tokenItemViewState, kingfisherImageCache: .default)
                .defaultRoundedBackground(with: Colors.Background.action)
                .padding(.bottom, 14)

            VStack(spacing: 0) {
                GetTokenActionRowView(
                    icon: Assets.plus24,
                    title: Localization.commonBuy,
                    subtitle: Localization.buyTokenDescription
                )
                .asTappableRow { viewModel.handleViewEvent(.buyTapped) }

                GetTokenActionRowView(
                    icon: Assets.exchangeMini,
                    title: Localization.commonExchange,
                    subtitle: Localization.exсhangeTokenDescription
                )
                .asTappableRow { viewModel.handleViewEvent(.exchangeTapped) }

                GetTokenActionRowView(
                    icon: Assets.arrowDownMini,
                    title: Localization.commonReceive,
                    subtitle: Localization.receiveTokenDescription
                )
                .asTappableRow { viewModel.handleViewEvent(.receiveTapped) }
            }
            .defaultRoundedBackground(with: Colors.Background.action, verticalPadding: 0, horizontalPadding: 0)
            .padding(.bottom, 24)

            MainButton(
                title: Localization.commonLater,
                style: .secondary,
                action: { viewModel.handleViewEvent(.laterTapped) }
            )
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .padding(.top, 12)
    }
}

// MARK: - Convenience for tappable actions

private extension GetTokenActionRowView {
    func asTappableRow(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            self
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
        }
    }
}
