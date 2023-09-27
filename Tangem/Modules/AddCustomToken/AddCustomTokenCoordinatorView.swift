//
//  AddCustomTokenCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct AddCustomTokenCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: AddCustomTokenCoordinator

    init(coordinator: AddCustomTokenCoordinator) {
        self.coordinator = coordinator
    }

    var body: some View {
        NavigationView {
            ZStack {
                if let rootViewModel = coordinator.rootViewModel {
                    AddCustomTokenView(viewModel: rootViewModel)
                        .navigationLinks(links)
                }

                sheets
            }
        }
    }

    @ViewBuilder
    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.networkSelectorModel) {
                AddCustomTokenNetworkSelectorView(viewModel: $0)
            }
    }

    @ViewBuilder
    private var sheets: some View {
        EmptyView()
    }
}
