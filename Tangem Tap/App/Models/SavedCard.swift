//
//  SavedCard.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct SavedCard: Codable {
    let cardId: String
    let wallets: [SavedCardWallet]
    
    static func savedCard(from card: Card) -> SavedCard {
        let wallets: [SavedCardWallet] = card.wallets.compactMap {
            guard
                let pubKey = $0.publicKey,
                let curve = $0.curve
            else { return nil }
            
            return SavedCardWallet(publicKey: pubKey, curve: curve)
        }
        
        return .init(cardId: card.cardId ?? "", wallets: wallets)
    }
}

struct SavedCardWallet: Codable {
    let publicKey: Data
    let curve: EllipticCurve
}
