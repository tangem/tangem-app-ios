//
//  EnvironmentSetupCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct EnvironmentSetupCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: EnvironmentSetupCoordinator

    init(coordinator: EnvironmentSetupCoordinator) {
        self.coordinator = coordinator
    }

    var body: some View {
        ZStack {
            if let rootViewModel = coordinator.rootViewModel {
                EnvironmentSetupView(viewModel: rootViewModel)
                    .navigationLinks(links)
            }

            sheets
        }
    }

    @ViewBuilder
    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.supportedBlockchainsPreferencesViewModel) {
                SupportedBlockchainsPreferencesView(viewModel: $0)
            }
    }

    @ViewBuilder
    private var sheets: some View {
        EmptyView()
    }
}
