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
                    GachaWelcomeView(viewModel: viewModel, onCloseButtonAction: coordinator.dismiss)
                case .stories(let viewModel):
                    GachaStoriesView(viewModel: viewModel)
                case .main(let viewModel):
                    GachaMainView(viewModel: viewModel, onBackButtonAction: coordinator.dismiss)
                }
            }
            .transition(Constants.stateTransition)
        }
    }
}

// MARK: - Constants

private extension GachaCoordinatorView {
    enum Constants {
        static let stateTransition: AnyTransition = .opacity.animation(.easeIn)
    }
}
