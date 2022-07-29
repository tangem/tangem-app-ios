//
//  UserWalletListCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct UserWalletListCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: UserWalletListCoordinator

    init(coordinator: UserWalletListCoordinator) {
        self.coordinator = coordinator
    }

    var body: some View {
        ZStack {
            if let rootViewModel = coordinator.rootViewModel {
                UserWalletListView(viewModel: rootViewModel)
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
