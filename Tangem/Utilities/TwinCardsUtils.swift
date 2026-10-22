//
//  TwinCardsUtils.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

enum TwinCardsUtils {
    static func isTwinCard(_ card: Card) -> Bool {
        series(for: card) != nil
    }

    static func series(for card: Card) -> TwinCardSeries? {
        TwinCardSeries.series(for: card.cardId)
    }

    static func makeCombinedWalletKey(for walletPublicKey: Data, pairPublicKey: Data) -> Data? {
        return try? Secp256k1Utils().sum(compressedPubKey1: walletPublicKey, compressedPubKey2: pairPublicKey)
    }
}
