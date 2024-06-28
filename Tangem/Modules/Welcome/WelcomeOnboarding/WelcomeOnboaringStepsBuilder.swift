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

    @MainActor
    func buildSteps() async -> [WelcomeOnbordingStep] {
        var steps = [WelcomeOnbordingStep]()

        if !AppSettings.shared.termsOfServicesAccepted.contains(AppConstants.tosURL.absoluteString) {
            steps.append(.tos)
        }

        if await pushNotificationsAvailabilityProvider.isAvailable {
            steps.append(.pushNotifications)
        }

        return steps
    }
}
