//
//  WalletInfo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk
import TangemHotSdk
import TangemFoundation

enum WalletInfo: Codable {
    case cardWallet(CardInfo)
    case mobileWallet(HotWalletInfo)

    var hasBackupCards: Bool {
        switch self {
        case .cardWallet(let cardInfo):
            cardInfo.card.backupStatus?.isActive ?? false
        case .mobileWallet:
            false
        }
    }

    var tangemApiAuthData: TangemApiTarget.AuthData {
        switch self {
        case .cardWallet(let cardInfo):
            TangemApiTarget.AuthData(cardId: cardInfo.card.cardId, cardPublicKey: cardInfo.card.cardPublicKey)
        case .mobileWallet:
            TangemApiTarget.AuthData(cardId: "", cardPublicKey: Data())
        }
    }

    var analyticsContextData: AnalyticsContextData {
        switch self {
        case .cardWallet(let cardInfo):
            let config = UserWalletConfigFactory().makeConfig(cardInfo: cardInfo)
            return AnalyticsContextData(
                card: cardInfo.card,
                productType: config.productType,
                embeddedEntry: config.embeddedBlockchain,
                userWalletId: UserWalletId(config: config)
            )

        case .mobileWallet:
            return AnalyticsContextData(
                productType: .hotWallet,
                batchId: "",
                firmware: "",
                baseCurrency: nil
            )
        }
    }

    var refcodeProvider: RefcodeProvider? {
        switch self {
        case .cardWallet(let cardInfo):
            if let userWalletId = UserWalletId(cardInfo: cardInfo) {
                return CommonExpressRefcodeProvider(
                    userWalletId: userWalletId,
                    cardId: cardInfo.card.cardId,
                    batchId: cardInfo.card.batchId
                )
            }

            return nil
        case .mobileWallet:
            return nil
        }
    }
}

struct HotWalletInfo: Codable {
    var hasMnemonicBackup: Bool
    var hasICloudBackup: Bool
    var isAccessCodeSet: Bool
    var keys: [KeyInfo]
}

struct CardInfo: Codable {
    var card: CardDTO
    var walletData: DefaultWalletData
    var primaryCard: PrimaryCard?
    var associatedCardIds: Set<String>

    var cardIdFormatted: String {
        if case .twin(_, let twinData) = walletData {
            return AppTwinCardIdFormatter.format(cid: card.cardId, cardNumber: twinData.series.number)
        } else {
            return AppCardIdFormatter(cid: card.cardId).formatted()
        }
    }
}
