//
//  AddCustomTokenNetworkSelectorCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct AddCustomTokenNetworkSelectorCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: AddCustomTokenNetworkSelectorCoordinator

    init(coordinator: AddCustomTokenNetworkSelectorCoordinator) {
        self.coordinator = coordinator
    }

    var body: some View {
        ZStack {
            if let rootViewModel = coordinator.rootViewModel {
                AddCustomTokenNetworkSelectorView(viewModel: rootViewModel)
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
        EmptyView()
    }
}
