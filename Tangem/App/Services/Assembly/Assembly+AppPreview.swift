//
//  Assembly+AppPreview.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

struct PreviewData {
    static var previewNoteCardOnboardingInput: OnboardingInput {
        OnboardingInput(steps: .singleWallet([.createWallet, .success]),
                        cardInput: .cardModel(PreviewCard.cardanoNote.cardModel),
                        cardsPosition: nil,
                        welcomeStep: nil,
                        currentStepIndex: 0,
                        successCallback: nil)
    }
    
    static var previewTwinOnboardingInput: OnboardingInput {
        .init(steps: .twins([.intro(pairNumber: "0128"),
                             .first, .second, .third,
                             .topup, .done]),
              cardInput: .cardModel(PreviewCard.twin.cardModel),
              cardsPosition: nil,
              welcomeStep: nil,
              currentStepIndex: 0,
              successCallback: nil)
    }
    
    static var previewWalletOnboardingInput: OnboardingInput {
        .init(steps: .wallet([.createWallet, .backupIntro, .selectBackupCards, .backupCards, .success]),
              cardInput: .cardModel(PreviewCard.tangemWalletEmpty.cardModel),
              cardsPosition: nil,
              welcomeStep: nil,
              currentStepIndex: 0,
              successCallback: nil)
    }
}
