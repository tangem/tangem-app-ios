//
//  CommonExpressProviderManagerFactory.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct CommonExpressProviderManagerFactory: ExpressProviderManagerFactory {
    private let expressAPIProvider: ExpressAPIProvider
    private let mapper: ExpressManagerMapper
    private let analyticsLogger: ExpressAnalyticsLogger
    private let requiresTransactionSizeValidation: Bool

    init(
        expressAPIProvider: ExpressAPIProvider,
        mapper: ExpressManagerMapper,
        analyticsLogger: ExpressAnalyticsLogger,
        requiresTransactionSizeValidation: Bool
    ) {
        self.expressAPIProvider = expressAPIProvider
        self.mapper = mapper
        self.analyticsLogger = analyticsLogger
        self.requiresTransactionSizeValidation = requiresTransactionSizeValidation
    }

    func makeExpressProviderManager(provider: ExpressProvider) -> ExpressProviderManager? {
        switch provider.type {
        case .dex, .dexBridge:
            return DEXExpressProviderManager(
                provider: provider,
                expressAPIProvider: expressAPIProvider,
                mapper: mapper,
                analyticsLogger: analyticsLogger,
                requiresTransactionSizeValidation: requiresTransactionSizeValidation
            )
        case .cex:
            return CEXExpressProviderManager(
                provider: provider,
                expressAPIProvider: expressAPIProvider,
                mapper: mapper
            )
        case .onramp, .unknown:
            return nil
        }
    }
}
