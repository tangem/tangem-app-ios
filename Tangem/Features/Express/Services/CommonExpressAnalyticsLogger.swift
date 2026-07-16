//
//  CommonExpressAnalyticsLogger.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemExpress

struct CommonExpressAnalyticsLogger {
    private let tokenItem: TokenItem

    init(tokenItem: TokenItem) {
        self.tokenItem = tokenItem
    }
}

// MARK: - ExpressAnalyticsLogger

extension CommonExpressAnalyticsLogger: ExpressAnalyticsLogger {
    func bestProviderSelected(_ provider: ExpressAvailableProvider) {
        guard provider.provider.id.lowercased() == "changelly",
              provider.provider.recommended == true else {
            return
        }

        Analytics.log(
            .promoChangellyActivity,
            params: [.state: provider.isBest ? .native : .recommended]
        )
    }

    func logGasEstimationOverrideError(_ error: any Error) {
        var params: [Analytics.ParameterKey: String] = [
            .token: tokenItem.currencySymbol,
            .blockchain: tokenItem.blockchain.displayName,
            .errorMessage: error.localizedDescription,
        ]

        if let rpcHost = error.lastRetryHostForAnalytics {
            params[.rpcProvider] = rpcHost
        }

        Analytics.log(event: .swapGasEstimationOverrideError, params: params)
    }

    func logAppError(_ error: any Error, provider: ExpressProvider) {
        Analytics.log(
            event: .onrampAppErrors,
            params: [
                .token: tokenItem.currencySymbol,
                .provider: provider.name,
                .errorDescription: error.localizedDescription,
            ]
        )
    }

    func logExpressAPIError(_ error: ExpressAPIError, provider: ExpressProvider, paymentMethod: OnrampPaymentMethod) {
        Analytics.log(
            event: .onrampErrors,
            params: [
                .token: tokenItem.currencySymbol,
                .provider: provider.name,
                .errorCode: error.errorCode.rawValue.description,
                .paymentMethod: paymentMethod.name,
            ]
        )
    }
}
