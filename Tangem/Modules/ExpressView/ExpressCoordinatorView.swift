//
//  ExpressCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct ExpressCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: ExpressCoordinator

    init(coordinator: ExpressCoordinator) {
        self.coordinator = coordinator
    }

    var body: some View {
        NavigationView {
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
            .sheet(item: $coordinator.swappingTokenListViewModel) {
                SwappingTokenListView(viewModel: $0)
            }

        NavHolder()
            .bottomSheet(item: $coordinator.swappingApproveViewModel) {
                SwappingApproveView(viewModel: $0)
            }
            .bottomSheet(item: $coordinator.expressFeeSelectorViewModel) {
                ExpressFeeBottomSheetView(viewModel: $0)
            }

        NavHolder()
            .sheet(item: $coordinator.swappingSuccessCoordinator) {
                SwappingSuccessCoordinatorView(coordinator: $0)
            }
    }
}
