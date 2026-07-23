//
//  UserWalletCardsBackupStatusReportService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol UserWalletCardsBackupStatusReportService {
    /// Reports the given cards and seed usage for a wallet's backup state to the back-end.
    /// Fire-and-forget: the request runs on a background task and failures are logged, not propagated.
    func report(status: UserWalletCardsBackupStatus, userWalletId: String)

    /// Fetches the stored cards and backup state for a wallet from the back-end.
    func fetchCards(userWalletId: String) async throws -> [UserWalletCardBackupStatus]
}

extension InjectedValues {
    var userWalletCardsBackupStatusReportService: UserWalletCardsBackupStatusReportService {
        get { Self[UserWalletCardsBackupStatusReportServiceInjectionKey.self] }
        set { Self[UserWalletCardsBackupStatusReportServiceInjectionKey.self] = newValue }
    }
}

// MARK: - Private implementation

private struct UserWalletCardsBackupStatusReportServiceInjectionKey: InjectionKey {
    static var currentValue: UserWalletCardsBackupStatusReportService = CommonUserWalletCardsBackupStatusReportService()
}
