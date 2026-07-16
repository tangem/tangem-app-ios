//
//  CommonUserWalletCardsBackupStatusReportService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import TangemFoundation

final class CommonUserWalletCardsBackupStatusReportService {
    private let api: TangemApiService

    init(api: TangemApiService = InjectedValues[\.tangemApiService]) {
        self.api = api
    }
}

extension CommonUserWalletCardsBackupStatusReportService: UserWalletCardsBackupStatusReportService {
    func report(status: UserWalletCardsBackupStatus, userWalletId: String) {
        let request = WalletCardsDTO.Request(
            cards: status.cards.map(mapToDTO),
            usedSeed: status.isImported
        )

        // [REDACTED_TODO_COMMENT]
        // [REDACTED_INFO]
        runTask(in: self) { service in
            do {
                try await service.api.saveWalletCards(userWalletId: userWalletId, cards: request)
            } catch {
                AppLogger.error("Failed to report wallet cards backup state", error: error)
            }
        }
    }

    func fetchCards(userWalletId: String) async throws -> [UserWalletCardBackupStatus] {
        let response = try await api.getWalletCards(userWalletId: userWalletId)
        return response.cards.map(mapToDomain)
    }
}

// MARK: - Mapping

private extension CommonUserWalletCardsBackupStatusReportService {
    func mapToDTO(_ card: UserWalletCardBackupStatus) -> WalletCardsDTO.Card {
        WalletCardsDTO.Card(
            cardId: card.cardId,
            cardPublicKey: card.cardPublicKey.hexString,
            role: mapToWire(card.role),
            backupStatus: card.backupStatus?.rawValue,
            curves: card.curves.map(\.rawValue),
            errorCode: card.errorCode?.description,
            errorMessage: card.errorMessage
        )
    }

    func mapToDomain(_ card: WalletCardsDTO.Card) -> UserWalletCardBackupStatus {
        UserWalletCardBackupStatus(
            cardId: card.cardId,
            cardPublicKey: Data(hexString: card.cardPublicKey),
            role: mapToDomain(role: card.role),
            backupStatus: card.backupStatus.flatMap(UserWalletCardBackupStatus.BackupStatus.init(rawValue:)),
            curves: card.curves.compactMap(EllipticCurve.init(rawValue:)),
            errorCode: card.errorCode.flatMap { Int($0) },
            errorMessage: card.errorMessage
        )
    }

    // MARK: - Role

    func mapToWire(_ role: UserWalletCardBackupStatus.Role?) -> String? {
        switch role {
        case .primary: return "primary"
        case .backup(let index): return "backup\(index)"
        case nil: return nil
        }
    }

    func mapToDomain(role: String?) -> UserWalletCardBackupStatus.Role? {
        guard let role else { return nil }

        if role == "primary" {
            return .primary
        }

        let prefix = "backup"
        guard role.hasPrefix(prefix), let index = Int(role.dropFirst(prefix.count)) else {
            return nil
        }

        return .backup(index: index)
    }
}
