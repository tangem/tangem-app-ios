//
//  ExpressCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI

struct ExpressCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: ExpressCoordinator

    var body: some View {
        NavigationStack {
            ZStack {
                if let rootViewModel = coordinator.rootViewModel {
                    ExpressView(viewModel: rootViewModel)
                }

                sheets
            }
        }
    }

    @ViewBuilder
    private var sheets: some View {
        NavHolder()
            .sheet(item: $coordinator.expressTokensListViewModel) {
                ExpressTokensListView(viewModel: $0)
            }
            .sheet(item: $coordinator.swapTokenSelectorViewModel) {
                SwapTokenSelectorView(viewModel: $0)
            }
            .floatingSheetContent(for: SendFeeSelectorViewModel.self) {
                SendFeeSelectorView(viewModel: $0)
            }
            .bottomSheet(
                item: $coordinator.expressApproveViewModel,
                backgroundColor: Colors.Background.tertiary
            ) {
                ExpressApproveView(viewModel: $0)
            }
            .bottomSheet(
                item: $coordinator.expressProvidersSelectorViewModel,
                backgroundColor: Colors.Background.tertiary
            ) {
                ExpressProvidersSelectorView(viewModel: $0)
            }

        NavHolder()
            .sheet(item: $coordinator.swappingSuccessCoordinator) {
                SwappingSuccessCoordinatorView(coordinator: $0)
                    .interactiveDismissDisabled(true)
            }
    }
}
