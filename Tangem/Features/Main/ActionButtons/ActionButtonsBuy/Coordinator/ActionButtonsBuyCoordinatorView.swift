//
//  ActionButtonsBuyCoordinatorView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct ActionButtonsBuyCoordinatorView: View {
    @ObservedObject var coordinator: ActionButtonsBuyCoordinator

    var body: some View {
        ZStack {
            switch coordinator.viewState {
            case .none:
                EmptyView()
            case .tokenList(let actionButtonsBuyViewModel):
                NavigationView {
                    ActionButtonsBuyView(viewModel: actionButtonsBuyViewModel)
                }
            case .newTokenList(let actionButtonsBuyViewModel):
                NavigationView {
                    NewActionButtonsBuyView(viewModel: actionButtonsBuyViewModel)
                }
                .transition(SendTransitions.transition)
            case .onramp(let sendCoordinator):
                SendCoordinatorView(coordinator: sendCoordinator)
                    .transition(SendTransitions.transition)
            }

            sheets
        }
        .animation(SendTransitions.animation, value: coordinator.viewState)
    }

    @ViewBuilder
    private var sheets: some View {
        NavHolder()
            .sheet(item: $coordinator.addToPortfolioBottomSheetInfo, content: { addToPortfolioSheet($0) })
    }

    private func addToPortfolioSheet(_ info: HotCryptoAddToPortfolioModel) -> some View {
        HotCryptoAddToPortfolioBottomSheet(
            info: info,
            action: {
//                coordinator.actionButtonsBuyViewModel?.handleViewAction(.addToPortfolio(info.token))
            }
        )
        .adaptivePresentationDetents()
        .background(Colors.Background.tertiary)
    }
}
