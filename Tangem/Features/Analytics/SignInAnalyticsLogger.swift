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

    func logSignInEvent(signInType: Analytics.SignInType) {
        guard let selectedModel = userWalletRepository.selectedModel else {
            return
        }

        Analytics.log(event: .signedIn, params: [
            .signInType: signInType.rawValue,
            .walletsCount: String(walletsCount),
            .walletType: seedStateParameter(userWalletModel: selectedModel).rawValue,
        ])
    }

    func logSignInButtonWalletEvent(signInType: Analytics.SignInType, userWalletModel: UserWalletModel) {
        Analytics.log(
            event: .signInButtonWallet,
            params: [
                .signInType: signInType.rawValue,
                .walletsCount: String(walletsCount),
                .walletType: seedStateParameter(userWalletModel: userWalletModel).rawValue,
            ],
            contextParams: .custom(userWalletModel.analyticsContextData)
        )
    }

    private func seedStateParameter(userWalletModel: UserWalletModel) -> Analytics.ParameterValue {
        let hasSeedPhrase = userWalletModel.config.productType == .mobileWallet || userWalletModel.hasImportedWallets
        return .seedState(for: hasSeedPhrase)
    }
}
