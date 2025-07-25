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
    private let commonStepsBuilder = CommonOnboardingStepsBuilder()

    private var otherSteps: [SingleCardOnboardingStep] {
        var steps: [SingleCardOnboardingStep] = []

        if commonStepsBuilder.shouldAddSaveWalletsStep {
            steps.append(.saveUserWallet)
        }

        if commonStepsBuilder.shouldAddPushNotificationsStep {
            steps.append(.pushNotifications)
        }

        return steps
    }

    init(hasWallets: Bool) {
        self.hasWallets = hasWallets
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
