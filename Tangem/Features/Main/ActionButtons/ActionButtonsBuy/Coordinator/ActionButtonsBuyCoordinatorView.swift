//
//  ActionButtonsBuyCoordinatorView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
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
                        .sheet(item: $coordinator.addToPortfolioBottomSheetInfo, content: { addToPortfolioSheet($0) })
                }
            case .newTokenList(let actionButtonsBuyViewModel):
                NavigationView {
                    NewActionButtonsBuyView(viewModel: actionButtonsBuyViewModel)
                        .sheet(item: $coordinator.addToPortfolioBottomSheetInfo, content: { addToPortfolioSheet($0) })
                }
                .transition(SendTransitions.transition)
            case .onramp(let sendCoordinator):
                SendCoordinatorView(coordinator: sendCoordinator)
                    .transition(SendTransitions.transition)
            }
        }
        .animation(SendTransitions.animation, value: coordinator.viewState)
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
