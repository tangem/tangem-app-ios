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
            NavigationView {
                if let model = coordinator.manageTokensViewModel {
                    ManageTokensView(viewModel: model)
                }
            }
            .navigationViewStyle(.stack)

            sheets
        }
    }

    @ViewBuilder
    private var sheets: some View {
        NavHolder()
            .sheet(item: $coordinator.networkSelectorCoordinator) {
                ManageTokensNetworkSelectorCoordinatorView(coordinator: $0)
            }
    }
}
