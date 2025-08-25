//
//  NoteOnboardingStepsBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct NoteOnboardingStepsBuilder {
    private let cardId: String
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

    init(
        cardId: String,
        hasWallets: Bool
    ) {
        self.cardId = cardId
        self.hasWallets = hasWallets
    }
}

extension NoteOnboardingStepsBuilder: OnboardingStepsBuilder {
    func buildOnboardingSteps() -> OnboardingSteps {
        var steps = [SingleCardOnboardingStep]()

        if hasWallets {
            if !AppSettings.shared.cardsStartedActivation.contains(cardId) {
                steps.append(contentsOf: otherSteps)
            } else {
                steps.append(contentsOf: otherSteps + [.topup, .successTopup])
            }
        } else {
            steps.append(contentsOf: [.createWallet] + otherSteps + [.topup, .successTopup])
        }

        return .singleWallet(steps)
    }

    func buildBackupSteps() -> OnboardingSteps? {
        return nil
    }
}
