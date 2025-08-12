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
import TangemVisa

struct UserWalletConfigFactory {
    func makeConfig(walletInfo: WalletInfo) -> UserWalletConfig {
        switch walletInfo {
        case .cardWallet(let cardInfo):
            makeConfig(cardInfo: cardInfo)
        case .mobileWallet(let hotWalletInfo):
            makeConfig(hotWalletInfo: hotWalletInfo)
        }
    }

    func makeConfig(cardInfo: CardInfo) -> UserWalletConfig {
        let isDemo = DemoUtil().isDemoCard(cardId: cardInfo.card.cardId)
        let isS2CCard = cardInfo.card.issuer.name.lowercased() == "start2coin"

        switch cardInfo.walletData {
        case .none:
            // old multiwallet
            if cardInfo.card.firmwareVersion <= .backupAvailable {
                return LegacyConfig(card: cardInfo.card, walletData: nil)
            }
            let isWallet2 = cardInfo.card.firmwareVersion >= .ed25519Slip0010Available

            switch (isWallet2, isDemo) {
            case (true, _):
                return Wallet2Config(card: cardInfo.card, isDemo: isDemo)
            case (false, true): // [REDACTED_TODO_COMMENT]
                return GenericDemoConfig(card: cardInfo.card)
            case (false, false):
                return GenericConfig(card: cardInfo.card)
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
        case .visa(let activationLocalState):
            return VisaConfig(card: cardInfo.card, activationLocalState: activationLocalState)
        }
    }

    func makeConfig(hotWalletInfo: HotWalletInfo) -> HotUserWalletConfig {
        return HotUserWalletConfig(hotWalletInfo: hotWalletInfo)
    }
}
