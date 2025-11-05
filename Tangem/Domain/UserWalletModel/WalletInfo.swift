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
import TangemMobileWalletSdk
import TangemFoundation

enum WalletInfo: Codable {
    case cardWallet(CardInfo)
    case mobileWallet(MobileWalletInfo)

    var hasBackupCards: Bool {
        switch self {
        case .cardWallet(let cardInfo):
            cardInfo.card.backupStatus?.isActive ?? false
        case .mobileWallet:
            false
        }
    }

    var tangemApiAuthData: TangemApiAuthorizationData? {
        switch self {
        case .cardWallet(let cardInfo):
            return TangemApiAuthorizationData(cardId: cardInfo.card.cardId, cardPublicKey: cardInfo.card.cardPublicKey)
        case .mobileWallet:
            return nil
        }
    }

    var analyticsContextData: AnalyticsContextData {
        switch self {
        case .cardWallet(let cardInfo):
            cardInfo.analyticsContextData
        case .mobileWallet(let info):
            info.analyticsContextData
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

    var keys: WalletKeys {
        switch self {
        case .cardWallet(let cardInfo): .cardWallet(keys: cardInfo.card.wallets)
        case .mobileWallet(let mobileWalletInfo): .mobileWallet(keys: mobileWalletInfo.keys)
        }
    }
}

struct MobileWalletInfo: Codable, AnalyticsContextDataProvider {
    var hasMnemonicBackup: Bool
    var hasICloudBackup: Bool
    var accessCodeStatus: UserWalletAccessCodeStatus
    var keys: [KeyInfo]

    var analyticsContextData: AnalyticsContextData {
        AnalyticsContextData.mobileWallet
    }
}

struct CardInfo: Codable, AnalyticsContextDataProvider {
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

    var analyticsContextData: AnalyticsContextData {
        let config = UserWalletConfigFactory().makeConfig(cardInfo: self)
        let data = AnalyticsContextData(
            card: card,
            productType: config.productType,
            embeddedEntry: config.embeddedBlockchain,
            userWalletId: UserWalletId(config: config)
        )

        return data
    }
}
