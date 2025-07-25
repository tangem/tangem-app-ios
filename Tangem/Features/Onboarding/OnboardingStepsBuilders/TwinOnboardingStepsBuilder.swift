//
//  TwinOnboardingStepsBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct TwinOnboardingStepsBuilder {
    private let cardId: String
    private let hasWallets: Bool
    private let twinData: TwinData
    private let commonStepsBuilder = CommonOnboardingStepsBuilder()

    private var otherSteps: [TwinsOnboardingStep] {
        var steps: [TwinsOnboardingStep] = []

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
        hasWallets: Bool,
        twinData: TwinData
    ) {
        self.cardId = cardId
        self.hasWallets = hasWallets
        self.twinData = twinData
    }
}

extension TwinOnboardingStepsBuilder: OnboardingStepsBuilder {
    func buildOnboardingSteps() -> OnboardingSteps {
        var steps = [TwinsOnboardingStep]()

        if !AppSettings.shared.isTwinCardOnboardingWasDisplayed { // show intro only once
            AppSettings.shared.isTwinCardOnboardingWasDisplayed = true // [REDACTED_TODO_COMMENT]
            let twinPairNumber = twinData.series.pair.number
            steps.append(.intro(pairNumber: "#\(twinPairNumber)"))
        }

        if !hasWallets { // twin without created wallet. Start onboarding
            steps.append(contentsOf: TwinsOnboardingStep.twinningProcessSteps)
            steps.append(contentsOf: otherSteps)
            steps.append(contentsOf: TwinsOnboardingStep.topupSteps)
            return .twins(steps)
        } else { // twin with created wallet
            if twinData.pairPublicKey == nil { // is not twinned
                steps.append(contentsOf: TwinsOnboardingStep.twinningProcessSteps)
                steps.append(contentsOf: otherSteps)
                steps.append(contentsOf: TwinsOnboardingStep.topupSteps)
                return .twins(steps)
            } else { // is twinned
                if AppSettings.shared.cardsStartedActivation.contains(cardId) { // card is in onboarding process, go to topup
                    steps.append(contentsOf: otherSteps)
                    steps.append(contentsOf: TwinsOnboardingStep.topupSteps)
                    return .twins(steps)
                } else { // unknown twin, ready to use, go to main
                    steps.append(contentsOf: otherSteps)
                    return .twins(steps)
                }
            }
        }
    }

    func buildBackupSteps() -> OnboardingSteps? {
        return nil
    }
}
