//
//  MobileCleanupUtil.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemMobileWalletBackup
import TangemMobileWalletSdk

enum MobileCleanupUtil {
    static func cleanAfterUpgrade(walletId: UserWalletId, mobileWalletInfo: MobileWalletInfo) {
        cleanMobileWallet(walletId: walletId)
        cleanBackupAfterUpgrade(walletId: walletId, mobileWalletInfo: mobileWalletInfo)
    }

    static func cleanMobileWallet(walletId: UserWalletId) {
        let mobileSdk = CommonMobileWalletSdk()
        do {
            try mobileSdk.delete(walletIDs: [walletId])
        } catch {
            AppLogger.error("Failed to delete mobile wallet keys:", error: error)
        }
    }

    static func cleanBackupAfterUpgrade(walletId: UserWalletId, mobileWalletInfo: MobileWalletInfo) {
        let analyticsContextData = mobileWalletInfo.analyticsContextData

        if mobileWalletInfo.hasSocialLogin {
            cleanSocialBackupAfterUpgrade(walletId: walletId, analyticsContextData: analyticsContextData)
        } else {
            cleanICloudBackup(walletId: walletId, analyticsContextData: analyticsContextData)
        }
    }

    static func cleanICloudBackup(walletId: UserWalletId, analyticsContextData: AnalyticsContextData) {
        runTask(isDetached: true) {
            await deleteICloudBackups(
                walletId: walletId,
                analyticsContextData: analyticsContextData
            )
        }
    }

    static func deleteSocialBackup(walletId: UserWalletId) async throws {
        let backupManager = CommonMobileWalletSocialBackupManager(destination: .iCloud)
        try await backupManager.deleteBackup(userWalletId: walletId)
    }
}

// MARK: - Private methods

private extension MobileCleanupUtil {
    static func deleteICloudBackups(walletId: UserWalletId, analyticsContextData: AnalyticsContextData) async {
        do {
            let backupManager = CommonMobileWalletBackupManager(destination: .iCloud)
            try await backupManager.deleteBackups(walletId: walletId)
            logCloudBackupDeletedAnalytics(analyticsContextData: analyticsContextData)
        } catch {
            AppLogger.error("Failed to delete the cloud backup:", error: error)
            logCloudBackupDeletionErrorAnalytics(error: error, analyticsContextData: analyticsContextData)
        }
    }

    static func cleanSocialBackupAfterUpgrade(walletId: UserWalletId, analyticsContextData: AnalyticsContextData) {
        runTask(isDetached: true) {
            do {
                try await deleteSocialBackup(walletId: walletId)
                logSocialRecoveryDeletedAnalytics(analyticsContextData: analyticsContextData)
            } catch {
                AppLogger.error("Failed to delete the social backup:", error: error)
                logSocialRecoveryDeletionErrorAnalytics(error: error, analyticsContextData: analyticsContextData)
            }
        }
    }
}

// MARK: - Analytics

private extension MobileCleanupUtil {
    static func logCloudBackupDeletedAnalytics(analyticsContextData: AnalyticsContextData) {
        Analytics.log(.walletSettingsCloudBackupDeleted, contextParams: .custom(analyticsContextData))
    }

    static func logCloudBackupDeletionErrorAnalytics(
        error: Error,
        analyticsContextData: AnalyticsContextData
    ) {
        Analytics.log(
            event: .walletSettingsCloudBackupDeletionError,
            params: MobileBackupStatusUtil.errorAnalyticsParams(error),
            contextParams: .custom(analyticsContextData)
        )
    }

    static func logSocialRecoveryDeletedAnalytics(analyticsContextData: AnalyticsContextData) {
        Analytics.log(.walletSettingsSocialRecoveryDeleted, contextParams: .custom(analyticsContextData))
    }

    static func logSocialRecoveryDeletionErrorAnalytics(
        error: Error,
        analyticsContextData: AnalyticsContextData
    ) {
        Analytics.log(
            event: .walletSettingsSocialRecoveryDeletionError,
            params: MobileBackupStatusUtil.errorAnalyticsParams(error),
            contextParams: .custom(analyticsContextData)
        )
    }
}
