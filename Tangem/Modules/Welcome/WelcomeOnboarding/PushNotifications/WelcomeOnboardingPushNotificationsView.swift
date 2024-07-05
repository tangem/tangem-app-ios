//
//  WelcomeOnboardingPushNotificationsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct WelcomeOnboardingPushNotificationsView: View {
    private let viewModel: PushNotificationsPermissionRequestViewModel

    var body: some View {
        VStack(spacing: 0.0) {
            // Invisible navigation bar is used here to replicate layout from wallet onboarding
            NavigationBar(title: "")
                .hidden()

            FixedSpacer(height: 20.0, length: 20.0)

            PushNotificationsPermissionRequestView(
                viewModel: viewModel,
                topInset: -Constants.pushNotificationsPermissionRequestViewTopInset,
                buttonsAxis: .vertical
            )
        }
    }

    init(viewModel: PushNotificationsPermissionRequestViewModel) {
        self.viewModel = viewModel
    }
}

// MARK: - Constants

private extension WelcomeOnboardingPushNotificationsView {
    enum Constants {
        /// - Warning: must match `WalletOnboardingView.progressBarPadding`, `SingleCardOnboardingView.progressBarPadding`,
        /// `TwinsOnboardingView.progressBarPadding` and so on.
        static let pushNotificationsPermissionRequestViewTopInset = 10.0
    }
}

// MARK: - Previews

#Preview {
    let viewModel = PushNotificationsPermissionRequestViewModel(
        permissionManager: PushNotificationsPermissionManagerStub(),
        delegate: PushNotificationsPermissionRequestDelegateStub()
    )

    return VStack {
        WelcomeOnboardingPushNotificationsView(viewModel: viewModel)

        Spacer()

        WelcomeOnboardingPushNotificationsView(viewModel: viewModel)
    }
}
