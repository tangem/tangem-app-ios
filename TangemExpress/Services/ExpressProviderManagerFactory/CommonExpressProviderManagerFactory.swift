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
    private let allowanceProvider: AllowanceProvider
    private let feeProvider: FeeProvider
    private let mapper: ExpressManagerMapper

    init(
        expressAPIProvider: ExpressAPIProvider,
        allowanceProvider: AllowanceProvider,
        feeProvider: FeeProvider,
        mapper: ExpressManagerMapper
    ) {
        self.expressAPIProvider = expressAPIProvider
        self.allowanceProvider = allowanceProvider
        self.feeProvider = feeProvider
        self.mapper = mapper
    }

    func makeExpressProviderManager(provider: ExpressProvider) -> ExpressProviderManager? {
        switch provider.type {
        case .dex, .dexBridge:
            return DEXExpressProviderManager(
                provider: provider,
                expressAPIProvider: expressAPIProvider,
                allowanceProvider: allowanceProvider,
                feeProvider: feeProvider,
                mapper: mapper
            )
        case .cex:
            return CEXExpressProviderManager(
                provider: provider,
                expressAPIProvider: expressAPIProvider,
                feeProvider: feeProvider,
                mapper: mapper
            )
        case .onramp, .unknown:
            return nil
        }
    }
}
