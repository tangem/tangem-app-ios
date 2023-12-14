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
        let isS2CCard = cardInfo.card.issuer.name.lowercased() == "start2coin"
        let isRing = cardInfo.card.batchId == "AC17"

        switch cardInfo.walletData {
        case .none:
            // old multiwallet
            if cardInfo.card.firmwareVersion <= .backupAvailable {
                return LegacyConfig(card: cardInfo.card, walletData: nil)
            }

            if FirmwareVersion.visaRange.contains(cardInfo.card.firmwareVersion.doubleValue) {
                return VisaConfig(card: cardInfo.card)
            }

            let isWallet2 = cardInfo.card.firmwareVersion >= .ed25519Slip0010Available

            switch (isWallet2, isDemo) {
            case (true, _):
                return Wallet2Config(card: cardInfo.card, isDemo: isDemo, isRing: isRing)
            case (false, true): // [REDACTED_TODO_COMMENT]
                return GenericDemoConfig(card: cardInfo.card)
            case (false, false):
                return GenericConfig(card: cardInfo.card, isRing: isRing)
            }
        case .file(let noteData):
            if isS2CCard { // [REDACTED_TODO_COMMENT]
                return Start2CoinConfig(card: cardInfo.card, walletData: noteData)
            }

            if isDemo {
                return NoteDemoConfig(card: cardInfo.card, noteData: noteData)
            } else {
                return NoteConfig(card: cardInfo.card, noteData: noteData)
            }
        case .twin(let walletData, let twinData):
            return TwinConfig(card: cardInfo.card, walletData: walletData, twinData: twinData)
        case .legacy(let walletData):
            if isS2CCard {
                return Start2CoinConfig(card: cardInfo.card, walletData: walletData)
            }

            return LegacyConfig(card: cardInfo.card, walletData: walletData)
        }
    }
}
