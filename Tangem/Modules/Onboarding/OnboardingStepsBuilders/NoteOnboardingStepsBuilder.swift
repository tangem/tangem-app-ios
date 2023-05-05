//
//  NoteOnboardingStepsBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class NoteOnboardingStepsBuilder {
    private let card: CardDTO
    private let touId: String

    private var userWalletSavingSteps: [SingleCardOnboardingStep] {
        guard BiometricsUtil.isAvailable,
              !AppSettings.shared.saveUserWallets,
              !AppSettings.shared.askedToSaveUserWallets else {
            return []
        }

        return [.saveUserWallet]
    }

    init(card: CardDTO, touId: String) {
        self.card = card
        self.touId = touId
    }
}

extension NoteOnboardingStepsBuilder: OnboardingStepsBuilder {
    func buildOnboardingSteps() -> OnboardingSteps {
        var steps = [SingleCardOnboardingStep]()

        if !AppSettings.shared.termsOfServicesAccepted.contains(touId) {
            steps.append(.disclaimer)
        }

        if card.wallets.isEmpty {
            steps.append(contentsOf: [.createWallet] + userWalletSavingSteps + [.topup, .successTopup])
        } else {
            if !AppSettings.shared.cardsStartedActivation.contains(card.cardId) {
                steps.append(contentsOf: userWalletSavingSteps)
            } else {
                steps.append(contentsOf: userWalletSavingSteps + [.topup, .successTopup])
            }
        }

        return .singleWallet(steps)
    }

    func buildBackupSteps() -> OnboardingSteps? {
        return nil
    }
}
