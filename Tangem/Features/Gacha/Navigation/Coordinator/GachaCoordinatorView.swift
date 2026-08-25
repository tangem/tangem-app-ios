//
//  GachaCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct GachaCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: GachaCoordinator

    var body: some View {
        if let state = coordinator.state {
            Group {
                switch state {
                case .welcome(let viewModel):
                    GachaWelcomeView(viewModel: viewModel, onClose: coordinator.dismiss)
                case .stories(let viewModel):
                    GachaStoriesView(viewModel: viewModel)
                case .main(let viewModel):
                    GachaMainView(viewModel: viewModel, onBack: coordinator.dismiss)
                }
            }
            .transition(.opacity.animation(.easeIn))
        }
    }
}
