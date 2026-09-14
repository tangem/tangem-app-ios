//
//  CollectiblesCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct CollectiblesCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: CollectiblesCoordinator

    var body: some View {
        content
            .toolbar(.hidden, for: .navigationBar)
            .background(FeedPopGestureEnabler())
            .navigationLinks(links)
    }
}

private extension CollectiblesCoordinatorView {
    // MARK: - View properties

    @ViewBuilder
    var content: some View {
        if let state = coordinator.state {
            Group {
                switch state {
                case .welcome(let viewModel):
                    CollectiblesWelcomeView(viewModel: viewModel, onBack: coordinator.dismiss)
                case .stories(let viewModel):
                    CollectiblesStoriesView(viewModel: viewModel)
                case .main(let viewModel):
                    CollectiblesMainView(viewModel: viewModel, onBack: coordinator.dismiss)
                }
            }
            .transition(.opacity.animation(.easeIn))
        }
    }

    var links: some View {
        NavHolder()
            .navigation(item: $coordinator.machineViewModel) { viewModel in
                CollectiblesMachineView(viewModel: viewModel, onBack: coordinator.closeMachine)
                    .toolbar(.hidden, for: .navigationBar)
            }
    }
}
