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
                NavigationStack {
                    ActionButtonsBuyView(viewModel: actionButtonsBuyViewModel)
                }
                .transition(SendTransitions.transition)
            case .newTokenList(let actionButtonsBuyViewModel):
                NavigationStack {
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

    private var sheets: some View {
        NavHolder()
            .bottomSheet(
                item: $coordinator.addToPortfolioBottomSheetInfo,
                backgroundColor: Colors.Background.tertiary
            ) {
                HotCryptoAddToPortfolioBottomSheetView(viewModel: $0)
            }
    }
}
