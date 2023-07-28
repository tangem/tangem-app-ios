//
//  MainCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct MainCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: MainCoordinator

    var body: some View {
        ZStack {
            if let mainViewModel = coordinator.mainViewModel {
                MainView(viewModel: mainViewModel)
                    .navigationLinks(links)
            }

            sheets
        }
    }

    @ViewBuilder
    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.detailsCoordinator) {
                DetailsCoordinatorView(coordinator: $0)
            }
    }

    @ViewBuilder
    private var sheets: some View {
        EmptyView()
    }
}
