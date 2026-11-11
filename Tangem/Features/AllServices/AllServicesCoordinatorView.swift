//
//  AllServicesCoordinatorView.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct AllServicesCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: AllServicesCoordinator

    var body: some View {
        NavigationStack {
            if let viewModel = coordinator.rootViewModel {
                AllServicesView(viewModel: viewModel)
                    .navigationLinks(links)
            }
        }
    }

    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.addWalletSelectorCoordinator) {
                AddWalletSelectorCoordinatorView(coordinator: $0)
            }
    }
}
