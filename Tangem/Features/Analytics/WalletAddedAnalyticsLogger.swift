//
//  WalletAddedAnalyticsLogger.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct WalletAddedAnalyticsLogger {
    private let hadMobileWallet: Bool
    private let hadSingleMobileWallet: Bool

    init() {
        hadMobileWallet = [.mobile, .mixed].contains(UserWalletRepositoryModeHelper.mode)
        hadSingleMobileWallet = UserWalletRepositoryModeHelper.hasSingleMobileWallet
    }

    func logIfNeeded(source: Analytics.ParameterValue, contextData: AnalyticsContextData) {
        guard shouldLog else { return }

        Analytics.log(
            .settingsColdWalletAdded,
            params: [.source: source],
            analyticsSystems: .all,
            contextParams: .custom(contextData)
        )

        AppSettings.shared.isColdWalletAddedEventLogged = true
    }
}

// MARK: - Private

private extension WalletAddedAnalyticsLogger {
    var shouldLog: Bool {
        if FeatureProvider.isAvailable(.mobileWalletMultiCreation) {
            return hadMobileWallet && !AppSettings.shared.isColdWalletAddedEventLogged
        }

        return hadSingleMobileWallet
    }
}
