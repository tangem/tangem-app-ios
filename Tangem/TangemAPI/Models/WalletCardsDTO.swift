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
        let role: Role
        let backupStatus: BackupStatus
        /// `EllipticCurve` raw values (e.g. `secp256k1`, `ed25519`); may be empty.
        let curves: [String]
        /// Error captured while running the backup command on the card, if any.
        let errorCode: String?
        let errorMessage: String?

        enum Role: String, Codable {
            case primary
            case backup1
            case backup2
            case unknown

            init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                let raw = try container.decode(String.self)
                self = Role(rawValue: raw) ?? .unknown
            }
        }

        enum BackupStatus: String, Codable {
            case noBackup
            case cardLinked
            case active
            case unknown

            init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                let raw = try container.decode(String.self)
                self = BackupStatus(rawValue: raw) ?? .unknown
            }
        }
    }
}
