//
//  SingleCardOnboardingStepsBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct SingleCardOnboardingStepsBuilder {
    private let cardId: String
    private let hasWallets: Bool
    private let isMultiCurrency: Bool
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

    private var addTokensSteps: [SingleCardOnboardingStep] {
        isMultiCurrency ? [.addTokens] : []
    }

    init(
        cardId: String,
        hasWallets: Bool,
        isMultiCurrency: Bool
    ) {
        self.cardId = cardId
        self.hasWallets = hasWallets
        self.isMultiCurrency = isMultiCurrency
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
