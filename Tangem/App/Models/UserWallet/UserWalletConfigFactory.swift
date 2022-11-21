//
//  UserWalletConfigFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

struct UserWalletConfigFactory {
    private let cardInfo: CardInfo

    #warning("[REDACTED_TODO_COMMENT]")

    init(_ cardInfo: CardInfo) {
        self.cardInfo = cardInfo
    }

    func makeConfig() -> UserWalletConfig {
        let isDemo = DemoUtil().isDemoCard(cardId: cardInfo.card.cardId)

        switch cardInfo.walletData {
        case .none:
            let isSaltPay = SaltPayUtil().isSaltPayCard(batchId: cardInfo.card.batchId, cardId: cardInfo.card.cardId)

            if cardInfo.card.firmwareVersion <= .backupAvailable {
                return LegacyConfig(card: cardInfo.card, walletData: nil)
            }

            if isDemo {
                return GenericDemoConfig(card: cardInfo.card)
            } else if isSaltPay {
                return SaltPayConfig(card: cardInfo.card)
            } else {
                return GenericConfig(card: cardInfo.card)
            }
        case .file(let noteData):
            if isDemo {
                return NoteDemoConfig(card: cardInfo.card, noteData: noteData)
            } else {
                return NoteConfig(card: cardInfo.card, noteData: noteData)
            }
        case .twin(let walletData, let twinData):
            return TwinConfig(card: cardInfo.card, walletData: walletData, twinData: twinData)
        case .legacy(let walletData):
            if cardInfo.card.issuer.name.lowercased() == "start2coin" {
                return Start2CoinConfig(card: cardInfo.card, walletData: walletData)
            }

            return LegacyConfig(card: cardInfo.card, walletData: walletData)
        }
    }
}
