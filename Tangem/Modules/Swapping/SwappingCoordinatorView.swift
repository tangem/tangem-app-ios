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
                    .navigationLinks(links)
            }

            sheets
        }
    }

    @ViewBuilder
    private var links: some View {
        EmptyView()
    }

    @ViewBuilder
    private var sheets: some View {
        NavHolder()
            .bottomSheet(item: $coordinator.swappingPermissionViewModel,
                         viewModelSettings: .default) {
                SwappingPermissionView(viewModel: $0)
            }

        NavHolder()
            .bottomSheet(item: $coordinator.successSwappingViewModel,
                         viewModelSettings: .default) {
                SuccessSwappingView(viewModel: $0)
            }
    }
}
