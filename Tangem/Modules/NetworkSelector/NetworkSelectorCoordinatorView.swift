//
//  NetworkSelectorCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct NetworkSelectorCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: NetworkSelectorCoordinator

    init(coordinator: NetworkSelectorCoordinator) {
        self.coordinator = coordinator
    }

    var body: some View {
        ZStack {
            if let rootViewModel = coordinator.rootViewModel {
                NetworkSelectorView(viewModel: rootViewModel)
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
