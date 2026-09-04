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
    func makeProvider() -> PolymarketAPIProvider {
        let environment = PolymarketBFFEnvironment.current()

        return CommonPolymarketAPIProvider(
            baseURL: environment.baseURL,
            networkConfiguration: TangemProviderConfiguration(logOptions: .verbose),
            headers: environment.headers.map { APIHeaderKeyInfo(headerName: $0.key, headerValue: $0.value) }
        )
    }
}
