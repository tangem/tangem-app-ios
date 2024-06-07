//
//  WelcomeOnboaringStepsBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct WelcomeOnboaringStepsBuilder {
    func buildSteps() -> [WelcomeOnbordingStep] {
        var steps = [WelcomeOnbordingStep]()

        if !AppSettings.shared.termsOfServicesAccepted.contains(AppConstants.tosURL.absoluteString) {
            steps.append(.tos)
        }

        if FeatureProvider.isAvailable(.pushNotifications) {
            // [REDACTED_TODO_COMMENT]
            steps.append(.pushNotifications)
        }

        return steps
    }
}
