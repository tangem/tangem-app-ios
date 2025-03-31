//
//  ActionButtonsSwapCoordinatorView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization

struct ActionButtonsSwapCoordinatorView: View {
    @ObservedObject var coordinator: ActionButtonsSwapCoordinator

    var body: some View {
        NavigationView {
            ZStack {
                if let viewModel = coordinator.actionButtonsSwapViewModel {
                    ActionButtonsSwapView(viewModel: viewModel)
                        .opacity(coordinator.expressCoordinator == nil ? 1 : 0)
                        .animation(.easeIn, value: coordinator.expressCoordinator == nil)
                }

                if let expressCoordinator = coordinator.expressCoordinator {
                    ExpressCoordinatorView(coordinator: expressCoordinator)
                        .transition(.opacity.animation(.easeInOut))
                }
            }
            .navigationBarTitle(Text(Localization.actionButtonsSwapNavigationBarTitle), displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CloseButton(dismiss: { coordinator.dismiss() })
                }
            }
        }
    }
}
