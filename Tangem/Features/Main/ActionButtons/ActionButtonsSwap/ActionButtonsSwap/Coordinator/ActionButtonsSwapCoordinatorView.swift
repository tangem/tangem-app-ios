//
//  ActionButtonsSwapCoordinatorView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemUI

struct ActionButtonsSwapCoordinatorView: View {
    @ObservedObject var coordinator: ActionButtonsSwapCoordinator

    var body: some View {
        ZStack {
            switch coordinator.viewType {
            case .none:
                EmptyView()
            case .new(let viewModel):
                NavigationStack {
                    AccountsAwareActionButtonsSwapView(viewModel: viewModel)
                }
                .transition(SendTransitions.transition)
            case .swap(let sendCoordinator):
                SendCoordinatorView(coordinator: sendCoordinator)
                    .transition(SendTransitions.transition)
            }
        }
        .animation(SendTransitions.animation, value: coordinator.viewType?.id)
    }
}
