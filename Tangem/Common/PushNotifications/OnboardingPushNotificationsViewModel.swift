//
//  OnboardingPushNotificationsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

class OnboardingPushNotificationsViewModel: ObservableObject {
    @Published var allowButtonTitle: String
    @Published var laterButtonTitle: String

    private weak var delegate: OnboardingPushNotificationsDelegate?

    init(
        canPostpone: Bool = false,
        delegate: any OnboardingPushNotificationsDelegate
    ) {
        allowButtonTitle = Localization.commonAllow
        laterButtonTitle = canPostpone ? Localization.commonLater : Localization.commonCancel
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
