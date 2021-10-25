//
//  Assembly+AppPreview.swift
//  Tangem Tap
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
                            cardModel: previewCardViewModel,
                            cardImage: UIImage(named: "note_btc")!,
                            cardsPosition: nil,
                            welcomeStep: nil,
                            currentStepIndex: 0,
                            successCallback: nil)
    }
    
    var previewTwinOnboardingInput: OnboardingInput {
        .init(steps: .twins([.intro(pairNumber: "0128"),
                             .first, .second, .third,
                             .topup, .confetti, .done]),
              cardModel: .previewViewModel(for: .twin),
              cardImage: UIImage(named: "card_btc")!,
              cardsPosition: nil,
              welcomeStep: nil,
              currentStepIndex: 0,
              successCallback: nil)
    }
    
    var previewWalletOnboardingInput: OnboardingInput {
        .init(steps: .wallet([.backupCards, .success]),
              cardModel: previewCardViewModel,
              cardImage: UIImage(named: "wallet_card")!,
              cardsPosition: nil,
              welcomeStep: nil,
              currentStepIndex: 0,
              successCallback: nil)
    }
    
    var previewBlockchain: Blockchain {
        previewCardViewModel.wallets!.first!.blockchain
    }
}
