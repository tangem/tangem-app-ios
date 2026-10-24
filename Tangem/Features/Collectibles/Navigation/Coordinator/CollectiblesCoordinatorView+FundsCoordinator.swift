//
//  CollectiblesCoordinatorView+FundsCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

extension CollectiblesCoordinatorView {
    struct FundsCoordinatorView: CoordinatorView {
        @ObservedObject var coordinator: CollectiblesCoordinator.FundsCoordinator

        var body: some View {
            NavHolder()
                .navigation(item: $coordinator.tokenDetailsCoordinator) { TokenDetailsCoordinatorView(coordinator: $0) }
                .sheet(item: $coordinator.addFundsSheet, onDismiss: coordinator.addFundsSheetDidDismiss) { viewModel in
                    CollectiblesAddFundsSheetView(viewModel: viewModel)
                        .presentationDetents(idealHeight: CollectiblesAddFundsSheetView.Metrics.estimatedHeight)
                        .presentationDragIndicator(.hidden)
                }
                .sheet(item: $coordinator.sendCoordinator) { SendCoordinatorView(coordinator: $0) }
        }
    }
}
