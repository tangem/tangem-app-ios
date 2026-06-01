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

    init(
        expressAPIProvider: ExpressAPIProvider,
        mapper: ExpressManagerMapper
    ) {
        self.expressAPIProvider = expressAPIProvider
        self.mapper = mapper
    }

    func makeExpressProviderManager(
        provider: ExpressProvider,
        pair: ExpressManagerSwappingPair,
        rateType: ExpressProviderRateType
    ) throws -> ExpressAvailableProvider {
        switch provider.type {
        case .dex, .dexBridge, .cex:
            let context = ExpressProviderFlowContext(
                provider: provider,
                pair: pair,
                rateType: rateType,
                expressFeeProvider: pair.source.expressFeeProviderFactory.makeExpressFeeProvider(),
                expressAPIProvider: expressAPIProvider,
                mapper: mapper
            )

            let manager = CommonExpressProviderManager(
                context: context,
                flowTypeResolver: CommonExpressFlowTypeResolver()
            )

            return ExpressAvailableProvider(context: context, manager: manager)
        case .onramp, .unknown:
            throw ExpressManagerError.unsupportedProviderType
        }
    }
}
