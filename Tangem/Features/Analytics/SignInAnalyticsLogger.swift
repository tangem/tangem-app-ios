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

    func logSignInEvent(signInType: Analytics.SignInType) {
        guard let selectedModel = userWalletRepository.selectedModel else {
            return
        }

        Analytics.log(event: .signedIn, params: [
            .signInType: signInType.rawValue,
            .walletsCount: "\(userWalletRepository.models.count)",
            .walletType: Analytics.ParameterValue.seedState(for: selectedModel.hasImportedWallets).rawValue,
        ])
    }
}
