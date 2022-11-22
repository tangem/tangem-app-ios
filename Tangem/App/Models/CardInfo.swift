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

struct CardInfo {
    var card: Card
    var walletData: DefaultWalletData
    var primaryCard: PrimaryCard? = nil

    var cardIdFormatted: String {
        if case let .twin(_, twinData) = walletData {
            return AppTwinCardIdFormatter.format(cid: card.cardId, cardNumber: twinData.series.number)
        } else {
            return AppCardIdFormatter(cid: card.cardId).formatted()
        }
    }
}

struct ImageLoadDTO: Equatable {
    let cardId: String
    let cardPublicKey: Data
    let artwotkInfo: ArtworkInfo?
}
