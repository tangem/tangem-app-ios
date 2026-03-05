//
//  MobileOnboardingPushNotificationsStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization

final class MobileOnboardingPushNotificationsStep: MobileOnboardingFlowStep {
    private let viewModel: PushNotificationsPermissionRequestViewModel
    private let navigationTitle = Localization.onboardingTitleNotifications

    init(
        permissionManager: PushNotificationsPermissionManager,
        delegate: PushNotificationsPermissionRequestDelegate
    ) {
        viewModel = PushNotificationsPermissionRequestViewModel(
            permissionManager: permissionManager,
            delegate: delegate
        )
    }

    override func makeView() -> any View {
        PushNotificationsPermissionRequestView(
            viewModel: viewModel,
            topInset: 0,
            buttonsAxis: .vertical
        )
        .stepsFlowNavBar(title: navigationTitle)
    }
}
