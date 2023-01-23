//
//  SwappingCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct SwappingCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: SwappingCoordinator

    init(coordinator: SwappingCoordinator) {
        self.coordinator = coordinator
    }

    var body: some View {
        ZStack {
            if let rootViewModel = coordinator.rootViewModel {
                SwappingView(viewModel: rootViewModel)
            }

            sheets
        }
    }

    @ViewBuilder
    private var sheets: some View {
        NavHolder()
            .sheet(item: $coordinator.swappingTokenListViewModel) {
                SwappingTokenListView(viewModel: $0)
            }

        NavHolder()
            .bottomSheet(item: $coordinator.swappingPermissionViewModel) {
                SwappingPermissionView(viewModel: $0)
            }

        NavHolder()
            .sheet(item: $coordinator.successSwappingCoordinator) {
                SuccessSwappingCoordinatorView(coordinator: $0)
            }
    }
}
