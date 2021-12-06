//
//  SavedCard.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct SavedCard: Codable {
    let cardId: String
    let wallets: [SavedCardWallet]
    var derivedKeys: [Data: [ExtendedPublicKey]] = [:]
    
    static func savedCard(from cardInfo: CardInfo) -> SavedCard {
        let wallets: [SavedCardWallet] = cardInfo.card.wallets.map {
            .init(publicKey: $0.publicKey, curve: $0.curve, chainCode: $0.chainCode)
        }
        
        return .init(cardId: cardInfo.card.cardId, wallets: wallets, derivedKeys: cardInfo.derivedKeys)
    }
}

struct SavedCardWallet: Codable {
    let publicKey: Data
    let curve: EllipticCurve
    let chainCode: Data?
    
    public var extendedPublicKey: ExtendedPublicKey? {
        guard let chainCode = self.chainCode else {
            return nil
        }

        return ExtendedPublicKey(compressedPublicKey: publicKey, //no way to get uncompressed key here
                                 chainCode: chainCode,
                                 derivationPath: .init())
    }
}
