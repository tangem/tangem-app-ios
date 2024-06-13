//
//  OnboardingPushNotificationsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

class OnboardingPushNotificationsViewModel: ObservableObject {
    private weak var delegate: OnboardingPushNotificationsDelegate?

    init(delegate: any OnboardingPushNotificationsDelegate) {
        self.delegate = delegate
    }

    func didTapAllow() {
        // [REDACTED_TODO_COMMENT]
        delegate?.didFinishPushNotificationOnboarding()
    }

    func didTapLater() {
        delegate?.didFinishPushNotificationOnboarding()
    }
}
