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
    private let transactionValidator: ExpressProviderTransactionValidator

    init(
        expressAPIProvider: ExpressAPIProvider,
        mapper: ExpressManagerMapper,
        transactionValidator: ExpressProviderTransactionValidator
    ) {
        self.expressAPIProvider = expressAPIProvider
        self.mapper = mapper
        self.transactionValidator = transactionValidator
    }

    func makeExpressProviderManager(provider: ExpressProvider, pair: ExpressManagerSwappingPair) -> ExpressProviderManager? {
        switch provider.type {
        case .dex, .dexBridge:
            return DEXExpressProviderManager(
                provider: provider,
                swappingPair: pair,
                expressFeeProvider: pair.source.expressFeeProviderFactory.makeExpressFeeProvider(),
                expressAPIProvider: expressAPIProvider,
                mapper: mapper,
                transactionValidator: transactionValidator,
            )
        case .cex:
            return CEXExpressProviderManager(
                provider: provider,
                swappingPair: pair,
                expressFeeProvider: pair.source.expressFeeProviderFactory.makeExpressFeeProvider(),
                expressAPIProvider: expressAPIProvider,
                mapper: mapper
            )
        case .onramp, .unknown:
            return nil
        }
    }
}
