//
//  OnrampProvidersCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct OnrampProvidersCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: OnrampProvidersCoordinator

    init(coordinator: OnrampProvidersCoordinator) {
        self.coordinator = coordinator
    }

    var body: some View {
        NavigationView {
            ZStack {
                if let rootViewModel = coordinator.rootViewModel {
                    OnrampProvidersView(viewModel: rootViewModel)
                        .navigationLinks(links)
                }
            }
        }
    }

    @ViewBuilder
    private var links: some View {
        EmptyView()
    }
}
