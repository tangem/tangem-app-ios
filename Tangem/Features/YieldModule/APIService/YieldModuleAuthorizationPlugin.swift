//
//  YieldModuleAuthorizationPlugin.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct YieldModuleAuthorizationPlugin: PluginType {
    private let apiKeyProvider = YieldModuleAPIKeyProvider()

    func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        var request = request

        if let apiKeyHeader = apiKeyProvider.getApiKeyHeader() {
            request.headers.add(apiKeyHeader)
        } else {
            assertionFailure("Yield Module API key is empty — header not added")
        }

        return request
    }
}
