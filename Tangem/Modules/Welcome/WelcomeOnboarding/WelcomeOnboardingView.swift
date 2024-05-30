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
        VStack(spacing: 0) {
            content
            footer
        }
    }

    @ViewBuilder
    var content: some View {
        switch viewModel.viewState {
        case .tos(let tosStepViewModel):
            TOSStepView(viewModel: tosStepViewModel)
        case .pushNotifications(let pushNotificationsStepViewModel):
            PushNotificationsStepView(viewModel: pushNotificationsStepViewModel)
        case .none:
            EmptyView()
        }
    }

    var footer: some View {
        EmptyView()
    }
}

struct WelcomeOnboardingView_Preview: PreviewProvider {
    static let viewModel = WelcomeOnboardingViewModel(steps: [], coordinator: WelcomeOnboardingCoordinator())

    static var previews: some View {
        WelcomeOnboardingView(viewModel: viewModel)
    }
}
