//
//  MobileWalletCreationAnalyticsLogger.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct MobileWalletCreationAnalyticsLogger {
    func logWalletCreated(source: Analytics.ParameterValue) {
        logWalletCreatedSuccessfully(creationType: .walletCreationTypeNewSeed, source: source)
    }

    func logWalletRestored(source: Analytics.ParameterValue) {
        logWalletCreatedSuccessfully(creationType: .walletCreationTypeSeedImport, source: source)
    }

    func logWalletRestored(source: Analytics.ParameterValue, seedLength: Int, isPassphraseEmpty: Bool) {
        logWalletCreatedSuccessfully(
            creationType: .walletCreationTypeSeedImport,
            source: source,
            seedLength: "\(seedLength)",
            passphrase: isPassphraseEmpty ? .empty : .full
        )
    }
}

// MARK: - Private methods

private extension MobileWalletCreationAnalyticsLogger {
    func logWalletCreatedSuccessfully(
        creationType: Analytics.ParameterValue,
        source: Analytics.ParameterValue,
        seedLength: String = Constants.seedPhraseLength,
        passphrase: Analytics.ParameterValue = .empty
    ) {
        var params: [Analytics.ParameterKey: String] = [
            .creationType: creationType.rawValue,
            .seedLength: seedLength,
            .passphrase: passphrase.rawValue,
            .source: source.rawValue,
        ]

        params.enrich(with: ReferralAnalyticsHelper().getReferralParams())

        Analytics.log(
            event: .walletCreatedSuccessfully,
            params: params,
            analyticsSystems: .all,
            contextParams: .custom(.mobileWallet)
        )
    }
}

// MARK: - Constants

private extension MobileWalletCreationAnalyticsLogger {
    enum Constants {
        static let seedPhraseLength = "12"
    }
}
