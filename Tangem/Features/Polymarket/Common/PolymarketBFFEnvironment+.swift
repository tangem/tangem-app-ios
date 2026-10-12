//
//  PolymarketBFFEnvironment+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemPolymarket

extension PolymarketBFFEnvironment {
    static func current() -> PolymarketBFFEnvironment {
        PolymarketBFFEnvironment(baseURL: baseURL(), headers: TangemSdkNetworkHeadersProvider().getHeaders())
    }

    private static func baseURL() -> URL {
        let apiBaseURL = AppEnvironment.current.apiBaseUrl
        var components = URLComponents(url: apiBaseURL, resolvingAgainstBaseURL: false)
        components?.path = ""

        return components?.url ?? apiBaseURL
    }
}
