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
    let primaryCardId: String
    let cardInitializer: CardInitializer?
    let steps: OnboardingSteps
    let cardInput: CardInput
    let twinData: TwinData?
    var isStandalone = false
    var userWalletToDelete: UserWalletId? // for twins. [REDACTED_TODO_COMMENT]
}

extension OnboardingInput {
    enum CardInput {
        case cardInfo(_ cardInfo: CardInfo)
        case userWalletModel(_ userWalletModel: UserWalletModel)
        case cardId(_ cardId: String)

        var emailData: [EmailCollectedData] {
            switch self {
            case .cardInfo(let cardInfo):
                let factory = UserWalletConfigFactory(cardInfo)
                return factory.makeConfig().emailData
            case .userWalletModel(let userWalletModel):
                return userWalletModel.emailData
            case .cardId:
                return []
            }
        }

        var demoBackupDisabledLocalizedReason: String? {
            switch self {
            case .cardInfo(let cardInfo):
                let factory = UserWalletConfigFactory(cardInfo)
                return factory.makeConfig().getFeatureAvailability(.backup).disabledLocalizedReason
            case .userWalletModel(let userWalletModel):
                return userWalletModel.config.getDisabledLocalizedReason(for: .backup)
            case .cardId:
                return nil
            }
        }

        var userWalletModel: UserWalletModel? {
            switch self {
            case .userWalletModel(let userWalletModel):
                return userWalletModel
            default:
                return nil
            }
        }

        var config: UserWalletConfig? {
            switch self {
            case .cardInfo(let cardInfo):
                let factory = UserWalletConfigFactory(cardInfo)
                return factory.makeConfig()
            case .userWalletModel(let userWalletModel):
                return userWalletModel.config
            case .cardId:
                return nil
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
            case .userWalletModel(let userWalletModel):
                return .init(
                    supportsOnlineImage: userWalletModel.config.hasFeature(.onlineImage),
                    cardId: userWalletModel.tangemApiAuthData.cardId,
                    cardPublicKey: userWalletModel.tangemApiAuthData.cardPublicKey
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
