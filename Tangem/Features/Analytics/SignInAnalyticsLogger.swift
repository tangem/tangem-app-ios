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
        let hasSeedPhrase = userWalletModel.config.productType == .mobileWallet || userWalletModel.hasImportedWallets
        let walletType = Analytics.ParameterValue.seedState(for: hasSeedPhrase)

        Analytics.log(
            event: event,
            params: [
                .signInType: signInType.rawValue,
                .walletsCount: String(walletsCount),
                .walletType: walletType.rawValue,
            ],
            contextParams: .custom(userWalletModel.analyticsContextData)
        )
    }
}
