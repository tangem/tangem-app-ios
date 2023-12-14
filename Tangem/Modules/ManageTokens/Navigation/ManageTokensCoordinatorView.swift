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
                    .onAppear(perform: model.onAppear)

                sheets
            }
        }
    }

    @ViewBuilder
    private var sheets: some View {
        NavHolder()
            .sheet(item: $coordinator.networkSelectorViewModel) { viewModel in
                NavigationView {
                    ZStack {
                        ManageTokensNetworkSelectorView(viewModel: viewModel)

                        links
                    }
                }
                .navigationViewStyle(.stack)
            }
            .sheet(item: $coordinator.addCustomTokenCoordinator) { coordinator in
                NavigationView {
                    AddCustomTokenCoordinatorView(coordinator: coordinator)
                }
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
