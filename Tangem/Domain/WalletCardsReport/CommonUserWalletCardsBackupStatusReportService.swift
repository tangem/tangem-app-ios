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
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService
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
                try await service.tangemApiService.saveWalletCards(userWalletId: userWalletId, cards: request)
            } catch {
                AppLogger.error("Failed to report wallet cards backup state", error: error)
            }
        }
    }

    func fetchCards(userWalletId: String) async throws -> [UserWalletCardBackupStatus] {
        let response = try await tangemApiService.getWalletCards(userWalletId: userWalletId)
        return response.cards.map(mapToDomain)
    }
}

// MARK: - Mapping

private extension CommonUserWalletCardsBackupStatusReportService {
    func mapToDTO(_ card: UserWalletCardBackupStatus) -> WalletCardsDTO.Card {
        WalletCardsDTO.Card(
            cardId: card.cardId,
            cardPublicKey: card.cardPublicKey.hexString,
            role: card.role?.wireValue,
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
            role: card.role.flatMap(UserWalletCardBackupStatus.Role.from(wireValue:)),
            backupStatus: card.backupStatus.flatMap(UserWalletCardBackupStatus.BackupStatus.init(rawValue:)),
            curves: card.curves.compactMap(EllipticCurve.init(rawValue:)),
            errorCode: card.errorCode.flatMap { Int($0) },
            errorMessage: card.errorMessage
        )
    }
}
