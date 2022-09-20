//
//  UserWalletConfigFactory.swift
//  Tangem
//
//  Created by Alexander Osokin on 11.08.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

struct UserWalletConfigFactory {
    private let cardInfo: CardInfo

    init(_ cardInfo: CardInfo) {
        self.cardInfo = cardInfo
    }

    func makeConfig() -> UserWalletConfig {
        let isDemo = DemoUtil().isDemoCard(cardId: cardInfo.card.cardId)

        switch cardInfo.walletData {
        case .none:
            if isDemo {
                return GenericDemoConfig(card: cardInfo.card)
            } else {
                if (cardInfo.card.cardId == "AC03000000070529") || (cardInfo.card.cardId == "AC03000000070537")  {
                    let token = Token(name: "Wrapped xDAI", symbol: "WxDAI", contractAddress: "0x4346186e7461cB4DF06bCFCB4cD591423022e417", decimals: 18)
                    return SaltPayConfig(card: cardInfo.card, walletData: WalletData(blockchain: Blockchain.saltPay.id, token: token))
                }
                return GenericConfig(card: cardInfo.card)
            }
        case .note(let noteData):
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
