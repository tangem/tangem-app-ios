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

    var dismissStyle: CollectiblesDismissStyle = .back

    var body: some View {
        content
            .toolbar(.hidden, for: .navigationBar)
            .background(FeedPopGestureEnabler())
            .navigationLinks(links)
            .overlay(stories)
    }
}

// MARK: - Presentation

extension View {
    func collectiblesFullScreenCover(item: Binding<CollectiblesCoordinator?>) -> some View {
        shtorkaCompatibleFullScreenCover(item: item) { coordinator in
            NavigationStack {
                CollectiblesCoordinatorView(coordinator: coordinator, dismissStyle: .close)
            }
        }
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
                    CollectiblesWelcomeView(viewModel: viewModel, dismissStyle: dismissStyle, onDismiss: coordinator.dismiss)
                case .main(let viewModel, let actionsMenuViewModel):
                    CollectiblesMainView(
                        viewModel: viewModel,
                        actionsMenuViewModel: actionsMenuViewModel,
                        dismissStyle: dismissStyle,
                        onDismiss: coordinator.dismiss
                    )
                }
            }
            .transition(.opacity.animation(.easeIn))
        }
    }

    @ViewBuilder
    var stories: some View {
        if let viewModel = coordinator.storiesViewModel {
            CollectiblesStoriesOverlayView(viewModel: viewModel, onDismiss: coordinator.closeStories)
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
