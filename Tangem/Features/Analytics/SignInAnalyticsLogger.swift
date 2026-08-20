//
//  SignInAnalyticsLogger.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct SignInAnalyticsLogger {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    private var walletsCount: Int { userWalletRepository.models.count }

    func logSignInEvent(signInType: Analytics.SignInType, userWalletModel: UserWalletModel) {
        log(
            event: .signedIn,
            signInType: signInType,
            userWalletModel: userWalletModel
        )
    }

    func logSignInButtonWalletEvent(signInType: Analytics.SignInType, userWalletModel: UserWalletModel) {
        log(
            event: .signInButtonWallet,
            signInType: signInType,
            userWalletModel: userWalletModel
        )
    }

    private func log(
        event: Analytics.Event,
        signInType: Analytics.SignInType,
        userWalletModel: UserWalletModel
    ) {
        let isMobileProductType = userWalletModel.config.productType == .mobileWallet
        let hasSeedPhrase = isMobileProductType || userWalletModel.hasImportedWallets
        let walletType = Analytics.ParameterValue.seedState(for: hasSeedPhrase)

        var params: [Analytics.ParameterKey: String] = [
            .signInType: signInType.rawValue,
            .walletsCount: String(walletsCount),
            .walletType: walletType.rawValue,
            .walletHasBackup: Analytics.ParameterValue.affirmativeOrNegative(for: userWalletModel.config.walletHasBackup).rawValue,
        ]

        if FeatureProvider.isAvailable(.mobileWalletBackup), isMobileProductType {
            let backupParams = MobileBackupStatusUtil.completedBackupsAnalyticsParams(config: userWalletModel.config)
            params.enrich(with: backupParams)
        }

        Analytics.log(
            event: event,
            params: params,
            contextParams: .custom(userWalletModel.analyticsContextData)
        )
    }
}
