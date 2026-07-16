//
//  ActionButtonsSellCoordinatorView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct ActionButtonsSellCoordinatorView: View {
    @ObservedObject var coordinator: ActionButtonsSellCoordinator

    var body: some View {
        ZStack {
            switch coordinator.viewState {
            case .tokenList(let viewModel):
                NavigationStack {
                    ActionButtonsSellView(viewModel: viewModel)
                }
                .transition(SendTransitions.transition)
            case .transfer(let viewModel):
                NavigationStack {
                    TransferView(viewModel: viewModel)
                }
                .transition(SendTransitions.transition)
            case .send(let sendCoordinator):
                SendCoordinatorView(coordinator: sendCoordinator)
                    .transition(SendTransitions.transition)
            case .swap(let sendCoordinator):
                SendCoordinatorView(coordinator: sendCoordinator)
                    .transition(SendTransitions.transition)
            case .none:
                EmptyView()
            }
        }
        .animation(SendTransitions.animation, value: coordinator.viewState)
    }
}
