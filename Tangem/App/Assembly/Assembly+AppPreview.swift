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

extension Assembly {
    var previewNoteCardOnboardingInput: OnboardingInput {
        OnboardingInput(steps: .singleWallet([.createWallet, .success]),
                            cardInput: .cardModel(previewCardViewModel),
                            cardsPosition: nil,
                            welcomeStep: nil,
                            currentStepIndex: 0,
                            successCallback: nil)
    }
    
    var previewTwinOnboardingInput: OnboardingInput {
        .init(steps: .twins([.intro(pairNumber: "0128"),
                             .first, .second, .third,
                             .topup, .done]),
              cardInput: .cardModel(.previewViewModel(for: .twin)),
              cardsPosition: nil,
              welcomeStep: nil,
              currentStepIndex: 0,
              successCallback: nil)
    }
    
    var previewWalletOnboardingInput: OnboardingInput {
        .init(steps: .wallet([.createWallet, .backupIntro, .selectBackupCards, .backupCards, .success]),
              cardInput: .cardModel(previewCardViewModel),
              cardsPosition: nil,
              welcomeStep: nil,
              currentStepIndex: 0,
              successCallback: nil)
    }
    
    var previewBlockchain: Blockchain {
        previewCardViewModel.wallets!.first!.blockchain
    }
    
    var previewBlockchainNetwork: BlockchainNetwork {
        .init(previewBlockchain)
    }
}
