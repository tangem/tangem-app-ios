//
//  CollectiblesCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct CollectiblesCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: CollectiblesCoordinator

    var dismissStyle: CollectiblesDismissStyle = .back

    var body: some View {
        content
            .background(FeedPopGestureEnabler())
            .shtorkaCompatibleFullScreenCover(item: $coordinator.machineViewModel, content: machine)
            .background(funds)
            .floatingSheetContent(for: ReceiveMainViewModel.self, viewBuilder: ReceiveMainView.init)
    }
}

private extension CollectiblesCoordinatorView {
    // MARK: - View properties

    @ViewBuilder
    var content: some View {
        if let state = coordinator.state {
            Group {
                switch state {
                case .welcome(let viewModel):
                    CollectiblesWelcomeView(viewModel: viewModel, dismissStyle: dismissStyle, onDismiss: coordinator.dismiss)
                case .main(let viewModel, let banners, let actionsMenuViewModel):
                    CollectiblesMainView(
                        viewModel: viewModel,
                        banners: banners,
                        actionsMenuViewModel: actionsMenuViewModel,
                        dismissStyle: dismissStyle,
                        onDismiss: coordinator.dismiss
                    )
                    .shtorkaCompatibleFullScreenCover(item: $coordinator.reconnectionViewModel, content: reconnection)
                }
            }
            .transition(.opacity.animation(.easeIn))
        }
    }

    func machine(_ viewModel: CollectiblesMachineViewModel) -> some View {
        MachineFlow(coordinator: coordinator, viewModel: viewModel)
    }

    func reconnection(_ viewModel: CollectiblesWelcomeViewModel) -> some View {
        CollectiblesWelcomeView(viewModel: viewModel, dismissStyle: .close, onDismiss: { coordinator.closeReconnection() })
    }

    @ViewBuilder
    var funds: some View {
        if let fundsCoordinator = coordinator.fundsCoordinator {
            FundsCoordinatorView(coordinator: fundsCoordinator)
        }
    }
}

// MARK: - Machine flow

private struct MachineFlow: View {
    @ObservedObject var coordinator: CollectiblesCoordinator

    let viewModel: CollectiblesMachineViewModel

    var body: some View {
        NavigationStack {
            CollectiblesMachineView(viewModel: viewModel, onClose: coordinator.closePackFlow)
                .toolbar(.hidden, for: .navigationBar)
                .background(FeedPopGestureEnabler())
                .navigation(item: $coordinator.confirmOrderViewModel) { viewModel in
                    CollectiblesConfirmOrderView(viewModel: viewModel, onBack: coordinator.closeConfirmOrder)
                        .toolbar(.hidden, for: .navigationBar)
                }
        }
    }
}
