//
//  ManageTokensCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct ManageTokensCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: ManageTokensCoordinator
    var body: some View {
        ZStack {
            if let rootViewModel = coordinator.rootViewModel {
                ManageTokensView(viewModel: rootViewModel)
            }

            sheets
        }
    }

    @ViewBuilder
    private var sheets: some View {
        NavHolder()
            .sheet(item: $coordinator.addCustomTokenCoordinator, content: {
                AddCustomTokenCoordinatorView(coordinator: $0)
            })
    }
}
