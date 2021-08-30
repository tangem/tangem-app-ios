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
    
    var previewNoteCardOnboardingInput: CardOnboardingInput {
        CardOnboardingInput(steps: .note([.read, .createWallet, .topup, .confetti, .goToMain]),
                            cardModel: previewCardViewModel,
                            currentStepIndex: 1,
                            cardImage: UIImage(named: "card_btc")!,
                            successCallback: nil)
    }
    
    var previewTwinOnboardingInput: CardOnboardingInput {
        .init(steps: .twins([.intro(pairNumber: "0128"), .first, .second, .third, .topup, .confetti, .done]),
              cardModel: .previewViewModel(for: .twin),
              currentStepIndex: 0,
              cardImage: UIImage(named: "card_btc")!,
              successCallback: nil)
    }
    
    var previewBlockchain: Blockchain {
        previewCardViewModel.wallets!.first!.blockchain
    }
}
