//
//  ManageTokensCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct ManageTokensCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: ManageTokensCoordinator

    var body: some View {
        ZStack {
            if let model = coordinator.manageTokensViewModel {
                ManageTokensView(viewModel: model)

                sheets
            }
        }
    }

    @ViewBuilder
    private var sheets: some View {
        NavHolder()
            .detentBottomSheet(
                item: $coordinator.networkSelectorViewModel,
                detents: [.medium, .large]
            ) { viewModel in
                NavigationView {
                    ManageTokensNetworkSelectorView(viewModel: viewModel)
                        .navigationLinks(links)
                }
                .navigationViewStyle(.stack)
            }
            .detentBottomSheet(
                item: $coordinator.addCustomTokenCoordinator,
                detents: [.large]
            ) { coordinator in
                AddCustomTokenCoordinatorView(coordinator: coordinator)
            }
    }

    @ViewBuilder
    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.walletSelectorViewModel) {
                WalletSelectorView(viewModel: $0)
            }
    }
}
