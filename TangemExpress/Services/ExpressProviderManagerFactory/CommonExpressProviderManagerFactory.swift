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
    private let featureFlags: ExpressFeatureFlagsProvider

    init(
        expressAPIProvider: ExpressAPIProvider,
        mapper: ExpressManagerMapper,
        featureFlags: ExpressFeatureFlagsProvider
    ) {
        self.expressAPIProvider = expressAPIProvider
        self.mapper = mapper
        self.featureFlags = featureFlags
    }

    func makeExpressProviderManager(
        provider: ExpressProvider,
        pair: ExpressManagerSwappingPair,
        supportedRateTypes: Set<ExpressProviderRateType>
    ) throws -> ExpressAvailableProvider {
        switch provider.type {
        case .dex, .dexBridge, .cex:
            let context = ExpressProviderFlowContext(
                provider: provider,
                pair: pair,
                expressFeeProvider: pair.source.expressFeeProviderFactory.makeExpressFeeProvider(),
                expressAPIProvider: expressAPIProvider,
                mapper: mapper,
                featureFlags: featureFlags
            )

            let manager = CommonExpressProviderManager(
                context: context,
                flowTypeResolver: CommonExpressFlowTypeResolver()
            )

            return ExpressAvailableProvider(
                context: context,
                manager: manager,
                supportedRateTypes: supportedRateTypes
            )
        case .onramp, .unknown:
            throw ExpressManagerError.unsupportedProviderType
        }
    }
}
