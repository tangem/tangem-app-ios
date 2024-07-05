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
            FixedSpacer(
                height: 20.0 + OnboardingLayoutConstants.navbarSize.height,
                length: 20.0
            )

            PushNotificationsPermissionRequestView(
                viewModel: viewModel,
                topInset: -OnboardingLayoutConstants.progressBarPadding,
                buttonsAxis: .vertical
            )
        }
    }

    init(viewModel: PushNotificationsPermissionRequestViewModel) {
        self.viewModel = viewModel
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
