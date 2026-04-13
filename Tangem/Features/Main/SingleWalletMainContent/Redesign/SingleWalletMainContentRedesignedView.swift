//
//  SingleWalletMainContentRedesignedView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemUIUtils

struct SingleWalletMainContentRedesignedView: View {
    @ObservedObject var viewModel: SingleWalletMainContentViewModel

    var body: some View {
        VStack(spacing: .unit(.x2)) {
            if let walletPromoBannerViewModel = viewModel.walletPromoBannerViewModel {
                WalletPromoBannerView(viewModel: walletPromoBannerViewModel)
            }

            PromotionNotificationsView(viewModel: viewModel.promotionNotificationsViewModel)

            NotificationBannerContainer(
                items: viewModel.notificationBannerItems,
                stackingType: .carousel
            )

            tokenCard
        }
        .padding(.horizontal, .unit(.x3))
        .bindAlert($viewModel.alert)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    @ViewBuilder
    private var tokenCard: some View {
        switch viewModel.redesignState?.tokenCardVariant {
        case .token(let tokenItemViewModel):
            MainPageTangemTokenRow(viewModel: tokenItemViewModel)
                .backgroundColor(Constants.tokenListBackgroundColor)
                .cornerRadiusContinuous(Constants.cornerRadius)

        case .account(let accountViewModel, let tokenItemViewModel):
            ExpandableAccountItemView(viewModel: accountViewModel) {
                MainPageTangemTokenRow(viewModel: tokenItemViewModel)
                    .backgroundColor(Constants.tokenListBackgroundColor)
            }
            .backgroundColor(Constants.tokenListBackgroundColor)
            .cornerRadiusContinuous(Constants.cornerRadius)

        case .none:
            EmptyView()
        }
    }
}

// MARK: - Constants

private extension SingleWalletMainContentRedesignedView {
    enum Constants {
        static let cornerRadius: CGFloat = .unit(.x5)
        static let tokenListBackgroundColor = Color.Tangem.Surface.level2
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    let userWalletModel = FakeUserWalletModel.xrpNote
    let walletModel = userWalletModel
        .accountModelsManager
        .cryptoAccountModels[0]
        .walletModelsManager
        .walletModels[0]

    SingleWalletMainContentRedesignedView(
        viewModel: SingleWalletMainContentViewModel(
            userWalletModel: userWalletModel,
            walletModel: walletModel,
            userWalletNotificationManager: FakeUserWalletNotificationManager(),
            promotionNotificationsManager: FakePromotionNotificationsManager(),
            pendingExpressTransactionsManager: FakePendingExpressTransactionsManager(),
            tokenNotificationManager: FakeUserWalletNotificationManager(),
            rateAppController: RateAppControllerStub(),
            tokenRouter: SingleTokenRoutableMock(),
            delegate: nil,
            coordinator: nil,
            accountModel: nil
        )
    )
}
#endif
