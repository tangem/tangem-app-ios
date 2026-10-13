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
    static func clean(walletId: UserWalletId, mobileWalletInfo: MobileWalletInfo) {
        cleanMobileWallet(walletId: walletId)
        cleanBackup(walletId: walletId, mobileWalletInfo: mobileWalletInfo)
    }

    static func cleanMobileWallet(walletId: UserWalletId) {
        let mobileSdk = CommonMobileWalletSdk()
        do {
            try mobileSdk.delete(walletIDs: [walletId])
        } catch {
            AppLogger.error("Failed to delete mobile wallet keys:", error: error)
        }
    }

    static func cleanBackup(walletId: UserWalletId, mobileWalletInfo: MobileWalletInfo) {
        let analyticsContextData = mobileWalletInfo.analyticsContextData

        if mobileWalletInfo.hasSocialLogin {
            cleanSocialBackup(walletId: walletId, analyticsContextData: analyticsContextData)
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

    static func cleanSocialBackup(walletId: UserWalletId, analyticsContextData: AnalyticsContextData) {
        runTask(isDetached: true) {
            await deleteSocialBackup(
                walletId: walletId,
                analyticsContextData: analyticsContextData
            )
        }
    }

    static func deleteSocialBackup(walletId: UserWalletId, analyticsContextData: AnalyticsContextData) async {
        do {
            let backupManager = CommonMobileWalletSocialBackupManager(destination: .iCloud)
            try await backupManager.deleteBackup(userWalletId: walletId)
            logSocialRecoveryDeletedAnalytics(analyticsContextData: analyticsContextData)
        } catch {
            AppLogger.error("Failed to delete the social backup:", error: error)
        }
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
}
