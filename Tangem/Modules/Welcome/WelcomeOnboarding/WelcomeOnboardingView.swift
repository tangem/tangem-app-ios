//
//  WelcomeOnboardingView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct WelcomeOnboardingView: View {
    @ObservedObject private var viewModel: WelcomeOnboardingViewModel

    init(viewModel: WelcomeOnboardingViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        content
            .background(.ultraThinMaterial)
            .transition(.opacity)
            .environment(\.colorScheme, .dark)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.viewState {
        case .tos(let viewModel):
            WelcomeOnboardingTOSView(viewModel: viewModel)
        case .pushNotifications(let viewModel):
            OnboardingPushNotificationsView(viewModel: viewModel, buttonsAxis: .vertical)
        case .none:
            EmptyView()
        }
    }
}

// #Preview {
//    WelcomeOnboardingView(
//        viewModel: WelcomeOnboardingViewModel(
//            steps: [.tos, .pushNotifications],
//            coordinator: WelcomeOnboardingCoordinator()
//        )
//    )
// }
