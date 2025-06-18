//
//  CardInfo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk
import TangemHotSdk

struct WalletInfo {
    let name: String
    let type: WalletInfoType
}

enum WalletInfoType {
    case card(CardInfo)
    case hot(HotWalletInfo)
}

struct HotWalletInfo: Codable {
    let publicKey: Data
    let wallets: [HotWallet]
}

struct CardInfo {
    var card: CardDTO
    var walletData: DefaultWalletData
    var primaryCard: PrimaryCard?

    var cardIdFormatted: String {
        if case .twin(_, let twinData) = walletData {
            return AppTwinCardIdFormatter.format(cid: card.cardId, cardNumber: twinData.series.number)
        } else {
            return AppCardIdFormatter(cid: card.cardId).formatted()
        }
    }
}
