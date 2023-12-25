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
            .iOS17UIKitSheet(item: $coordinator.expressTokensListViewModel) {
                ExpressTokensListView(viewModel: $0)
            }
            .bottomSheet(
                item: $coordinator.swappingApproveViewModel,
                settings: .init(backgroundColor: Colors.Background.tertiary)
            ) {
                SwappingApproveView(viewModel: $0)
            }
            .bottomSheet(
                item: $coordinator.expressFeeSelectorViewModel,
                settings: .init(backgroundColor: Colors.Background.tertiary)
            ) {
                ExpressFeeBottomSheetView(viewModel: $0)
            }
            .bottomSheet(
                item: $coordinator.expressProvidersSelectorViewModel,
                settings: .init(backgroundColor: Colors.Background.tertiary)
            ) {
                ExpressProvidersSelectorView(viewModel: $0)
            }

        NavHolder()
            .sheet(item: $coordinator.swappingSuccessCoordinator) {
                SwappingSuccessCoordinatorView(coordinator: $0)
            }
    }
}
