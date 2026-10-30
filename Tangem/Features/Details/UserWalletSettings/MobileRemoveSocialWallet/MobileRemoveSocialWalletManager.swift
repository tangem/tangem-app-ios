//
//  MobileRemoveSocialWalletManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

protocol MobileRemoveSocialWalletManager: AnyObject {
    var hasSeedBackup: Bool { get }
    var analyticsContextData: AnalyticsContextData { get }

    func removeWallet() async throws
}

final class CommonMobileRemoveSocialWalletManager {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    private let userWalletModel: UserWalletModel

    init(userWalletModel: UserWalletModel) {
        self.userWalletModel = userWalletModel
    }
}

// MARK: - MobileRemoveSocialWalletManager

extension CommonMobileRemoveSocialWalletManager: MobileRemoveSocialWalletManager {
    var hasSeedBackup: Bool {
        MobileBackupStatusUtil.hasMnemonicBackup(config: userWalletModel.config)
    }

    var analyticsContextData: AnalyticsContextData {
        userWalletModel.analyticsContextData
    }

    func removeWallet() async throws {
        let walletId = userWalletModel.userWalletId

        do {
            try await BackendAuthenticationRegistrar.unregisterSocialMobileWallet(id: walletId)
        } catch {
            logWalletDeletionErrorAnalytics(error)
            throw error
        }

        do {
            try await MobileCleanupUtil.deleteSocialBackup(walletId: walletId)
        } catch {
            AppLogger.error("Failed to delete the social backup:", error: error)
        }

        await runOnMain {
            userWalletRepository.delete(userWalletId: walletId)
        }

        logWalletDeletedAnalytics()
    }
}

// MARK: - Analytics

private extension CommonMobileRemoveSocialWalletManager {
    func logWalletDeletedAnalytics() {
        Analytics.log(.walletSettingsWalletDeleted, contextParams: .custom(analyticsContextData))
    }

    func logWalletDeletionErrorAnalytics(_ error: Error) {
        Analytics.log(
            event: .walletSettingsDeleteWalletError,
            params: MobileBackupStatusUtil.errorAnalyticsParams(error),
            contextParams: .custom(analyticsContextData)
        )
    }
}
