//
//  HotOnboardingPushNotificationsStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

final class HotOnboardingPushNotificationsStep: HotOnboardingFlowStep {
    private let viewModel: PushNotificationsPermissionRequestViewModel

    init(
        permissionManager: PushNotificationsPermissionManager,
        delegate: PushNotificationsPermissionRequestDelegate
    ) {
        viewModel = PushNotificationsPermissionRequestViewModel(
            permissionManager: permissionManager,
            delegate: delegate
        )
    }

    override func build() -> any View {
        PushNotificationsPermissionRequestView(
            viewModel: viewModel,
            topInset: 0,
            buttonsAxis: .vertical
        )
    }
}
