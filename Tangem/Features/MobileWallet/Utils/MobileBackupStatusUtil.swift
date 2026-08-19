//
//  MobileBackupStatusUtil.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct MobileBackupStatusUtil {
    private let userWalletModel: UserWalletModel

    init(userWalletModel: UserWalletModel) {
        self.userWalletModel = userWalletModel
    }
}

// MARK: - Stored status

extension MobileBackupStatusUtil {
    var hasMnemonicBackup: Bool {
        Self.hasMnemonicBackup(config: userWalletModel.config)
    }

    var hasICloudBackup: Bool {
        Self.hasICloudBackup(config: userWalletModel.config)
    }

    var hasBackup: Bool {
        Self.hasBackup(config: userWalletModel.config)
    }

    var isBackupNeeded: Bool {
        Self.isBackupNeeded(config: userWalletModel.config)
    }

    static func hasMnemonicBackup(config: UserWalletConfig) -> Bool {
        !config.hasFeature(.mnemonicBackup)
    }

    static func hasICloudBackup(config: UserWalletConfig) -> Bool {
        FeatureProvider.isAvailable(.mobileWalletBackup) && !config.hasFeature(.iCloudBackup)
    }

    static func hasBackup(config: UserWalletConfig) -> Bool {
        hasMnemonicBackup(config: config) || hasICloudBackup(config: config)
    }

    static func isBackupNeeded(config: UserWalletConfig) -> Bool {
        !hasBackup(config: config)
    }
}

// MARK: - Analytics

extension MobileBackupStatusUtil {
    static func completedBackupsAnalyticsParams(config: UserWalletConfig) -> [Analytics.ParameterKey: String] {
        var paramValues: [Analytics.ParameterValue] = []

        if hasMnemonicBackup(config: config) {
            paramValues.append(.backupTypeManual)
        }

        if hasICloudBackup(config: config) {
            paramValues.append(.backupTypeCloud)
        }

        guard paramValues.isNotEmpty else {
            return [:]
        }

        let paramValue = paramValues.map(\.rawValue).joined(separator: ", ")

        return [.completedBackups: paramValue]
    }

    static func errorAnalyticsParams(_ error: Error) -> [Analytics.ParameterKey: String] {
        [.errorMessage: error.localizedDescription]
    }
}
