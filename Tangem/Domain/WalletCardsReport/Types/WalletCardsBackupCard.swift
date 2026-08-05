//
//  WalletCardsBackupCard.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import TangemMacro
import TangemFoundation

/// The persisted latest known state of a single physical card.
struct WalletCardsBackupCard: Codable, Equatable {
    let cardId: String
    let cardPublicKey: Data
    var identity: Identity
    /// `nil` when the reporting step can't determine the role (a scan outside a ceremony). A known role is
    /// never overwritten with `nil` — see the repository merge.
    var role: Role?
    /// `nil` when the card's status can't be observed (an interrupted ceremony step). Like `role`, a known
    /// value is never overwritten with `nil`.
    var backupStatus: BackupStatus?
    var curves: [EllipticCurve]
    /// The error from the card's last failed backup command, cleared once the card is reported successfully.
    var errorCode: Int?
    var errorMessage: String?
}

// MARK: - Identity

extension WalletCardsBackupCard {
    /// The wallet a card belongs to. `.blank` while the wallet id can't be resolved yet — it carries the
    /// ceremony's primary card id, the key the repository later fills the whole group by.
    @CaseFlagable
    enum Identity: Codable, Equatable {
        case blank(primaryCardId: String)
        case filled(userWalletId: String, isImported: Bool)
    }
}

// MARK: - Role + BackupStatus

extension WalletCardsBackupCard {
    @RawCaseName
    enum Role: Equatable {
        case primary
        case backup(index: Int)

        /// Wire form used for persistence and the back end: `primary`, `backup1`, `backup2`, …
        var wireValue: String {
            switch self {
            case .primary: return rawCaseValue
            case .backup(let index): return "\(rawCaseValue)\(index)"
            }
        }

        static func from(wireValue: String) -> Role? {
            switch wireValue {
            case Role.primary.rawCaseValue:
                return .primary
            case let value:
                let backupPrefix = Role.backup(index: 0).rawCaseValue
                if value.hasPrefix(backupPrefix),
                   let index = Int(wireValue.dropFirst(backupPrefix.count)),
                   index > 0 {
                    return .backup(index: index)
                }

                return nil
            }
        }
    }

    enum BackupStatus: String, Codable {
        case noBackup
        case cardLinked
        case active

        init(_ status: Card.BackupStatus) {
            switch status {
            case .noBackup: self = .noBackup
            case .cardLinked: self = .cardLinked
            case .active: self = .active
            }
        }
    }
}

// MARK: - Role + Codable

extension WalletCardsBackupCard.Role: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let wireValue = try container.decode(String.self)

        guard let role = Self.from(wireValue: wireValue) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unknown role '\(wireValue)'")
        }

        self = role
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wireValue)
    }
}

// MARK: - CustomStringConvertible

extension WalletCardsBackupCard: CustomStringConvertible {
    var description: String {
        objectDescription("WalletCardsBackupCard", userInfo: [
            "cardId": "\(cardId.prefix(4))...\(cardId.suffix(4))",
            "identity": "\(identity)",
            "role": "\(role?.wireValue ?? "—")",
            "backupStatus": "\(backupStatus?.rawValue ?? "—")",
            "curves": "\(curves.count)",
            "error": "\(errorMessage ?? "-") (\(errorCode?.description ?? "-"))",
        ])
    }
}

extension WalletCardsBackupCard.Identity: CustomStringConvertible {
    var description: String {
        switch self {
        case .blank(let primaryCardId):
            return "blank(primary: \(primaryCardId.prefix(4))...\(primaryCardId.suffix(4)))"
        case .filled(let userWalletId, let isImported):
            return "filled(id: \(userWalletId.prefix(4))...\(userWalletId.suffix(4)), isImported: \(isImported))"
        }
    }
}
