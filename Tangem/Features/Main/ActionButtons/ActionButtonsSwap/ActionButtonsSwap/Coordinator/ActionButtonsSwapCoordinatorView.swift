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
            case .legacy(let viewModel):
                NavigationStack {
                    ActionButtonsSwapView(viewModel: viewModel)
                        .navigationBarTitle(Text(Localization.actionButtonsSwapNavigationBarTitle), displayMode: .inline)
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                CloseButton(dismiss: { coordinator.dismiss() })
                            }
                        }
                }
                .transition(.opacity)
            case .new(let viewModel):
                NavigationStack {
                    NewActionButtonsSwapView(viewModel: viewModel)
                }
                .transition(SendTransitions.transition)
            case .express(let expressCoordinator):
                ExpressCoordinatorView(coordinator: expressCoordinator)
                    .transition(SendTransitions.transition)
            }
        }
        .animation(SendTransitions.animation, value: coordinator.viewType?.id)
    }
}
