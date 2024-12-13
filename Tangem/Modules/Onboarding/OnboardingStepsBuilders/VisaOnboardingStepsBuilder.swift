//
//  VisaOnboardingStepsBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct VisaOnboardingStepsBuilder {
    private let isPushNotificationsAvailable: Bool

    private var otherSteps: [VisaOnboardingStep] {
        var steps: [VisaOnboardingStep] = []

        if BiometricsUtil.isAvailable,
           !AppSettings.shared.saveUserWallets,
           !AppSettings.shared.askedToSaveUserWallets {
            steps.append(.saveUserWallet)
        }

        if isPushNotificationsAvailable {
            steps.append(.pushNotifications)
        }

        return steps
    }

    private var approveSteps: [VisaOnboardingStep] {
        [
            .selectWalletForApprove,
            .approveUsingTangemWallet,
        ]
    }

    init(
        isPushNotificationsAvailable: Bool
    ) {
        self.isPushNotificationsAvailable = isPushNotificationsAvailable
    }
}

extension VisaOnboardingStepsBuilder: OnboardingStepsBuilder {
    func buildOnboardingSteps() -> OnboardingSteps {
        var steps = [VisaOnboardingStep]()

        steps.append(.welcome)
        steps.append(.accessCode)

        steps.append(contentsOf: approveSteps)
        steps.append(contentsOf: otherSteps)

        return .visa(steps)
    }

    func buildBackupSteps() -> OnboardingSteps? {
        return nil
    }
}
