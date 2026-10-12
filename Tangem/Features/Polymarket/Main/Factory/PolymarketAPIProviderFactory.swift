//
//  PolymarketAPIProviderFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemNetworkUtils
import TangemPolymarket

struct PolymarketAPIProviderFactory {
    func makeProvider(
        walletId: String,
        builderCodeStore: PolymarketBuilderCodeStore = InjectedValues[\.polymarketBuilderCodeStore]
    ) -> PolymarketAPIProvider {
        let environment = PolymarketBFFEnvironment.current()

        return CommonPolymarketAPIProvider(
            baseURL: environment.baseURL,
            networkConfiguration: TangemProviderConfiguration(
                logOptions: .verbose,
                urlSessionConfiguration: .polymarketConfiguration
            ),
            headers: environment.headers.map { APIHeaderKeyInfo(headerName: $0.key, headerValue: $0.value) },
            walletId: walletId,
            builderCodeStore: builderCodeStore
        )
    }
}
