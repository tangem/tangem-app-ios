//
//  SingleCardOnboardingStepsBuilder.swift
//  Tangem
//
//  Created by Alexander Osokin on 07.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct SingleCardOnboardingStepsBuilder {
    private let cardId: String
    private let hasWallets: Bool
    private let isMultiCurrency: Bool
    private let pushNotificationsAvailabilityProvider: PushNotificationsAvailabilityProvider

    private var otherSteps: [SingleCardOnboardingStep] {
        var steps: [SingleCardOnboardingStep] = []

        if BiometricsUtil.isAvailable,
           !AppSettings.shared.saveUserWallets,
           !AppSettings.shared.askedToSaveUserWallets {
            steps.append(.saveUserWallet)
        }

        if pushNotificationsAvailabilityProvider.isAvailable {
            steps.append(.pushNotifications)
        }

        return steps
    }

    private var addTokensSteps: [SingleCardOnboardingStep] {
        isMultiCurrency && FeatureProvider.isAvailable(.markets) ? [.addTokens] : []
    }

    init(
        cardId: String,
        hasWallets: Bool,
        isMultiCurrency: Bool,
        pushNotificationsAvailabilityProvider: PushNotificationsAvailabilityProvider
    ) {
        self.cardId = cardId
        self.hasWallets = hasWallets
        self.isMultiCurrency = isMultiCurrency
        self.pushNotificationsAvailabilityProvider = pushNotificationsAvailabilityProvider
    }
}

extension SingleCardOnboardingStepsBuilder: OnboardingStepsBuilder {
    func buildOnboardingSteps() -> OnboardingSteps {
        var steps = [SingleCardOnboardingStep]()

        if hasWallets {
            if AppSettings.shared.cardsStartedActivation.contains(cardId) {
                steps.append(contentsOf: otherSteps + addTokensSteps + [.success])
            } else {
                steps.append(contentsOf: otherSteps)
            }
        } else {
            steps.append(contentsOf: [.createWallet] + otherSteps + addTokensSteps + [.success])
        }

        return .singleWallet(steps)
    }

    func buildBackupSteps() -> OnboardingSteps? {
        return nil
    }
}
