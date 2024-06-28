//
//  OnboardingPushNotificationsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

final class OnboardingPushNotificationsViewModel: ObservableObject {
    @Published private(set) var allowButtonTitle: String
    @Published private(set) var laterButtonTitle: String

    private let permissionManager: PushNotificationsPermissionManager

    private weak var delegate: OnboardingPushNotificationsDelegate?

    init(
        permissionManager: PushNotificationsPermissionManager,
        delegate: OnboardingPushNotificationsDelegate
    ) {
        self.permissionManager = permissionManager
        self.delegate = delegate

        allowButtonTitle = Localization.commonAllow
        laterButtonTitle = permissionManager.canPostponePermissionRequest ? Localization.commonLater : Localization.commonCancel
    }

    func didTapAllow() {
        runTask(in: self) { viewModel in
            await viewModel.permissionManager.allowPermissionRequest()
            await runOnMain {
                viewModel.delegate?.didFinishPushNotificationOnboarding()
            }
        }
    }

    func didTapLater() {
        permissionManager.postponePermissionRequest()
        delegate?.didFinishPushNotificationOnboarding()
    }
}
