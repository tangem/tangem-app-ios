//
//  WalletCardsDTO.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum WalletCardsDTO {
    struct Request: Encodable {
        let cards: [Card]
        /// `true` when a seed phrase was used to create or import the wallet (including a hot-to-cold upgrade).
        let usedSeed: Bool
    }

    struct Response: Decodable {
        let cards: [Card]
    }

    struct Card: Codable {
        let cardId: String
        let cardPublicKey: String
        /// Wire value: `primary` or `backupN` (e.g. `backup1`). Mapped to a domain enum in the report service.
        let role: String?
        let backupStatus: String?
        /// `EllipticCurve` raw values (e.g. `secp256k1`, `ed25519`); may be empty.
        let curves: [String]
        /// Error captured while running the backup command on the card, if any.
        let errorCode: String?
        let errorMessage: String?
    }
}
