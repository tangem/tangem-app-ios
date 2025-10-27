//
//  OnboardingInput.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import UIKit
import TangemSdk
import TangemFoundation
import TangemMobileWalletSdk

struct OnboardingInput { // [REDACTED_TODO_COMMENT]
    let backupService: BackupService
    let primaryCardId: String
    let cardInitializer: CardInitializer?
    let pushNotificationsPermissionManager: PushNotificationsPermissionManager?
    let steps: OnboardingSteps
    let cardInput: CardInput
    let twinData: TwinData?
    var isStandalone = false
    var userWalletToDelete: UserWalletId? // for twins. [REDACTED_TODO_COMMENT]
    var mobileContext: MobileWalletContext? // for mobile wallet upgrade
}

extension OnboardingInput {
    enum CardInput {
        case cardInfo(_ cardInfo: CardInfo)
        case userWalletModel(_ userWalletModel: UserWalletModel, cardId: String, cardImageProvider: WalletImageProviding)
        case cardId(_ cardId: String)

        var emailData: [EmailCollectedData] {
            switch self {
            case .cardInfo(let cardInfo):
                let factory = UserWalletConfigFactory()
                return factory.makeConfig(cardInfo: cardInfo).emailData
            case .userWalletModel(let userWalletModel, _, _):
                return userWalletModel.emailData
            case .cardId:
                return []
            }
        }

        var demoBackupDisabledLocalizedReason: String? {
            switch self {
            case .cardInfo(let cardInfo):
                let factory = UserWalletConfigFactory()
                return factory.makeConfig(cardInfo: cardInfo).getFeatureAvailability(.backup).disabledLocalizedReason
            case .userWalletModel(let userWalletModel, _, _):
                return userWalletModel.config.getDisabledLocalizedReason(for: .backup)
            case .cardId:
                return nil
            }
        }

        var userWalletModel: UserWalletModel? {
            switch self {
            case .userWalletModel(let userWalletModel, _, _):
                return userWalletModel
            default:
                return nil
            }
        }

        var cardInfo: CardInfo? {
            switch self {
            case .cardInfo(let cardInfo):
                return cardInfo
            default:
                return nil
            }
        }

        var config: UserWalletConfig? {
            switch self {
            case .cardInfo(let cardInfo):
                let factory = UserWalletConfigFactory()
                return factory.makeConfig(cardInfo: cardInfo)
            case .userWalletModel(let userWalletModel, _, _):
                return userWalletModel.config
            case .cardId:
                return nil
            }
        }

        var cardImageProvider: WalletImageProviding {
            switch self {
            case .cardInfo(let cardInfo):
                return CardImageProvider(card: cardInfo.card)
            case .userWalletModel(_, _, let provider):
                return provider
            case .cardId(let cardId):
                return CardImageProvider(
                    input: CardImageProvider.Input(
                        cardId: cardId,
                        cardPublicKey: Data(),
                        issuerPublicKey: Data(),
                        firmwareVersionType: .release
                    )
                ) // we assume that cache exists
            }
        }

        func getContextParams() -> Analytics.ContextParams {
            switch self {
            case .cardInfo(let cardInfo):
                return .custom(cardInfo.analyticsContextData)
            case .userWalletModel(let userWalletModel, _, _):
                return .custom(userWalletModel.analyticsContextData)
            case .cardId:
                return .default
            }
        }
    }
}
