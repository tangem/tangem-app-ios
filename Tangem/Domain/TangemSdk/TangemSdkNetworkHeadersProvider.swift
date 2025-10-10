//
//  TangemSdkNetworkHeadersProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemFoundation

struct TangemSdkNetworkHeadersProvider {
    private let apiKeyProvider = TangemAPIKeyProvider()

    func getHeaders() -> [String: String] {
        var headers = DeviceInfo().asHeaders()

        if let apiKeyHeader = apiKeyProvider.getApiKeyHeader() {
            headers[apiKeyHeader.name] = apiKeyHeader.value
        }

        return headers
    }
}
