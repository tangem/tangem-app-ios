//
//  WelcomeOnboaringStepsBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct WelcomeOnboaringStepsBuilder {
    private let pushNotificationsAvailabilityProvider: PushNotificationsAvailabilityProvider

    init(
        pushNotificationsAvailabilityProvider: PushNotificationsAvailabilityProvider
    ) {
        self.pushNotificationsAvailabilityProvider = pushNotificationsAvailabilityProvider
    }

    func buildSteps() -> [WelcomeOnbordingStep] {
        var steps = [WelcomeOnbordingStep]()

        if !AppSettings.shared.termsOfServicesAccepted.contains(AppConstants.tosURL.absoluteString) {
            steps.append(.tos)
        }

        if pushNotificationsAvailabilityProvider.isAvailable {
            steps.append(.pushNotifications)
        }

        return steps
    }
}
