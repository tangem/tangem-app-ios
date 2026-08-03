//
//  CommonWalletCardsBackupReportService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

final class CommonWalletCardsBackupReportService {
    @Injected(\.walletCardsBackupReportRepository)
    private var repository: WalletCardsBackupReportRepository
}

// MARK: - WalletCardsBackupReportService

extension CommonWalletCardsBackupReportService: WalletCardsBackupReportService {
    func reportCard(_ card: WalletCardsCurrentlyProcessedCard, primaryCardId: String) {
        repository.store(card: card, primaryCardId: primaryCardId, error: nil)
    }

    func reportFailure(_ card: WalletCardsCurrentlyProcessedCard, primaryCardId: String, error: TangemSdkError) {
        repository.store(card: card, primaryCardId: primaryCardId, error: error)
    }
}
