//
//  OnboardingInput.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import UIKit
import TangemSdk

struct OnboardingInput { // [REDACTED_TODO_COMMENT]
    let backupService: BackupService
    let cardInteractor: (CardPreparable & CardResettable)?
    let steps: OnboardingSteps
    let cardInput: CardInput
    let twinData: TwinData?
    var isStandalone = false
    var userWalletToDelete: UserWallet? // for twins. [REDACTED_TODO_COMMENT]
    var stepsBuilder: OnboardingStepsBuilder? // for saltpay
}

extension OnboardingInput {
    enum CardInput {
        case cardInfo(_ cardInfo: CardInfo)
        case cardModel(_ cardModel: CardViewModel)
        case cardId(_ cardId: String)

        var cardModel: CardViewModel? {
            switch self {
            case .cardModel(let cardModel):
                return cardModel
            default:
                return nil
            }
        }

        var cardId: String {
            switch self {
            case .cardInfo(let cardInfo):
                return cardInfo.card.cardId
            case .cardModel(let cardModel):
                return cardModel.cardId
            case .cardId(let cardId):
                return cardId
            }
        }

        var imageLoadInput: ImageLoadInput {
            switch self {
            case .cardInfo(let cardInfo):
                let config = UserWalletConfigFactory(cardInfo).makeConfig()
                return .init(
                    supportsOnlineImage: config.hasFeature(.onlineImage),
                    cardId: cardInfo.card.cardId,
                    cardPublicKey: cardInfo.card.cardPublicKey
                )
            case .cardModel(let cardModel):
                return .init(
                    supportsOnlineImage: cardModel.supportsOnlineImage,
                    cardId: cardModel.cardId,
                    cardPublicKey: cardModel.cardPublicKey
                )
            case .cardId(let cardId):
                return .init(
                    supportsOnlineImage: true,
                    cardId: cardId,
                    cardPublicKey: Data()
                ) // we assume that cache exists
            }
        }
    }

    // [REDACTED_TODO_COMMENT]
    struct ImageLoadInput {
        let supportsOnlineImage: Bool
        let cardId: String
        let cardPublicKey: Data
    }
}
