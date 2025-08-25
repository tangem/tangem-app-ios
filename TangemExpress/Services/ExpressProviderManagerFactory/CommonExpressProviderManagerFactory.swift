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

    func makeExpressProviderManager(provider: ExpressProvider) -> ExpressProviderManager? {
        switch provider.type {
        case .dex, .dexBridge:
            return DEXExpressProviderManager(
                provider: provider,
                expressAPIProvider: expressAPIProvider,
                mapper: mapper
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
