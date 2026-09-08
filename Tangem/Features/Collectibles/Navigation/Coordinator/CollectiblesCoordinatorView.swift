//
//  CollectiblesCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct CollectiblesCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: CollectiblesCoordinator

    var body: some View {
        if let state = coordinator.state {
            Group {
                switch state {
                case .welcome(let viewModel):
                    CollectiblesWelcomeView(viewModel: viewModel, onClose: coordinator.dismiss)
                case .stories(let viewModel):
                    CollectiblesStoriesView(viewModel: viewModel)
                case .main(let viewModel):
                    NavigationStack {
                        CollectiblesMainView(viewModel: viewModel, onBack: coordinator.dismiss)
                    }
                }
            }
            .transition(.opacity.animation(.easeIn))
        }
    }
}
