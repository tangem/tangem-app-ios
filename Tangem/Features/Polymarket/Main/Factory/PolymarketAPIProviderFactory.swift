//
//  PolymarketAPIProviderFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemNetworkUtils
import TangemPolymarket

struct PolymarketAPIProviderFactory {
    func makeProvider() -> PolymarketAPIProvider {
        CommonPolymarketAPIProvider(
            baseURL: baseURL(),
            networkConfiguration: TangemProviderConfiguration(logOptions: .verbose),
            headers: makeHeaders()
        )
    }

    private func baseURL() -> URL {
        let apiBaseURL = AppEnvironment.current.apiBaseUrl
        var components = URLComponents(url: apiBaseURL, resolvingAgainstBaseURL: false)
        components?.path = ""
        return components?.url ?? apiBaseURL
    }

    private func makeHeaders() -> [APIHeaderKeyInfo] {
        var headers = DeviceInfo().asHeaders().map { APIHeaderKeyInfo(headerName: $0.key, headerValue: $0.value) }

        if let apiKeyHeader = TangemAPIKeyProvider().getApiKeyHeader() {
            headers.append(APIHeaderKeyInfo(headerName: apiKeyHeader.name, headerValue: apiKeyHeader.value))
        }

        return headers
    }
}
