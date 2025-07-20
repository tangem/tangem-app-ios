//
//  HotOnboardingPushNotificationsStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

struct HotOnboardingPushNotificationsStep: HotOnboardingFlowStep {
    var transformations: [TransformationModifier<AnyView>] = []

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

    func build() -> some View {
        PushNotificationsPermissionRequestView(
            viewModel: viewModel,
            topInset: 0,
            buttonsAxis: .vertical
        )
    }
}
