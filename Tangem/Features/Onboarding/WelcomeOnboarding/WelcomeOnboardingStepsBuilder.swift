//
//  WelcomeOnboardingStepsBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct WelcomeOnboardingStepsBuilder {
    private let isPushNotificationsAvailable: Bool

    init(isPushNotificationsAvailable: Bool) {
        self.isPushNotificationsAvailable = isPushNotificationsAvailable
    }

    func buildSteps() -> [WelcomeOnboardingStep] {
        var steps = [WelcomeOnboardingStep]()

        if isPushNotificationsAvailable {
            steps.append(.pushNotifications)
        }

        return steps
    }
}
