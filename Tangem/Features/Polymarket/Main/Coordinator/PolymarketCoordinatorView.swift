//
//  PolymarketCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemPolymarketUI
import TangemUI
import TangemUIUtils

struct PolymarketCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: PolymarketCoordinator

    var body: some View {
        content
            .toolbar(.hidden, for: .navigationBar)
            .background(FeedPopGestureEnabler())
            .navigationLinks(links)
            .fullScreenCover(item: $coordinator.redeem) { viewModel in
                PolymarketRedeemView(viewModel: viewModel)
                    .softTopScrollEdgeEffect()
            }
            .fullScreenCover(item: $coordinator.fastTradingActivation) { viewModel in
                PolymarketFastTradingActivationView(viewModel: viewModel)
            }
            .modalStatus(
                isPresented: $coordinator.isFastTradingActivationFailurePresented,
                onDismiss: { coordinator.fastTradingActivationFailureDidDismiss() },
                content: { fastTradingActivationFailure }
            )
            .polymarketOrderSheet(presenter: coordinator.orderPresenter, host: nil)
            .background(PolymarketMainSheetHost(coordinator: coordinator, isActive: coordinator.orderPresenter.order == nil))
    }

    @ViewBuilder
    private var content: some View {
        switch coordinator.viewState {
        case .welcome(let viewModel):
            PolymarketWelcomeView(viewModel: viewModel)
        case .main(let viewModel, _, _):
            PolymarketMainView(viewModel: viewModel)
        case nil:
            EmptyView()
        }
    }

    private var fastTradingActivationFailure: some View {
        ModalStatus(
            .warning,
            title: PolymarketFastTradingStrings.activationFailedTitle,
            description: PolymarketFastTradingStrings.activationFailedDescription
        )
        .actions(
            primary: TangemUI.Button(label: Localization.commonClose, accessibilityLabel: nil) {
                coordinator.closeFastTradingActivationFailure()
            },
            secondary: TangemUI.Button(label: PolymarketFastTradingStrings.activateSessionKey, accessibilityLabel: nil) {
                coordinator.activateFastTradingAfterFailure()
            }
        )
    }

    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.destination) { destination in
                switch destination {
                case .eventDetails(let coordinator):
                    PolymarketEventDetailsCoordinatorView(coordinator: coordinator)
                case .positionDetails(let coordinator):
                    PolymarketPositionDetailsCoordinatorView(coordinator: coordinator)
                case .myPositions(let coordinator):
                    PolymarketMyPositionsCoordinatorView(coordinator: coordinator)
                case .tokenDetails(let coordinator):
                    TokenDetailsCoordinatorView(coordinator: coordinator)
                case .activity(let coordinator):
                    PolymarketActivityCoordinatorView(coordinator: coordinator)
                case .fastTrading(let viewModel):
                    PolymarketFastTradingView(viewModel: viewModel)
                case .category(let coordinator):
                    PolymarketCategoryCoordinatorView(coordinator: coordinator)
                }
            }
    }
}
