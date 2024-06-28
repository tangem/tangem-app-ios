//
//  Start2CoinOnboardingStepsBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct Start2CoinOnboardingStepsBuilder {
    private let hasWallets: Bool
    private let pushNotificationsAvailabilityProvider: PushNotificationsAvailabilityProvider

    private var otherSteps: [SingleCardOnboardingStep] {
        var steps: [SingleCardOnboardingStep] = []

        if BiometricsUtil.isAvailable,
           !AppSettings.shared.saveUserWallets,
           !AppSettings.shared.askedToSaveUserWallets {
            steps.append(.saveUserWallet)
        }

        if PushNotificationsProvider.isAvailable {
            steps.append(.pushNotifications)
        }

        return steps
    }

    init(
        hasWallets: Bool,
        pushNotificationsAvailabilityProvider: PushNotificationsAvailabilityProvider
    ) {
        self.hasWallets = hasWallets
        self.pushNotificationsAvailabilityProvider = pushNotificationsAvailabilityProvider
    }
}

extension Start2CoinOnboardingStepsBuilder: OnboardingStepsBuilder {
    func buildOnboardingSteps() -> OnboardingSteps {
        var steps = [SingleCardOnboardingStep]()

        if hasWallets {
            steps.append(contentsOf: otherSteps)
        } else {
            steps.append(contentsOf: [.createWallet] + otherSteps + [.success])
        }

        return .singleWallet(steps)
    }

    func buildBackupSteps() -> OnboardingSteps? {
        return nil
    }
}
