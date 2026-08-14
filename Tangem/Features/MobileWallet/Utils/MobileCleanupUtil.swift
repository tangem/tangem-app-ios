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
        cleanBackupIfNeeded(walletId: walletId, mobileWalletInfo: mobileWalletInfo)
    }

    static func cleanMobileWallet(walletId: UserWalletId) {
        let mobileSdk = CommonMobileWalletSdk()
        do {
            try mobileSdk.delete(walletIDs: [walletId])
        } catch {
            AppLogger.error("Failed to delete mobile wallet keys:", error: error)
        }
    }

    static func cleanBackupIfNeeded(walletId: UserWalletId, mobileWalletInfo: MobileWalletInfo) {
        guard mobileWalletInfo.hasICloudBackup else {
            return
        }

        let analyticsContextData = mobileWalletInfo.analyticsContextData

        runTask(isDetached: true) {
            await deleteICloudBackups(
                walletId: walletId,
                analyticsContextData: analyticsContextData
            )
        }
    }
}

// MARK: - Private methods

private extension MobileCleanupUtil {
    static func deleteICloudBackups(walletId: UserWalletId, analyticsContextData: AnalyticsContextData) async {
        do {
            let backupManager = CommonMobileWalletBackupManager(destination: .iCloud)
            try await backupManager.deleteBackups(walletId: walletId)
            Analytics.log(.cloudBackupDeleted, contextParams: .custom(analyticsContextData))
        } catch {
            AppLogger.error("Failed to delete the cloud backup:", error: error)
            Analytics.log(.cloudBackupDeletionError, contextParams: .custom(analyticsContextData))
        }
    }
}
