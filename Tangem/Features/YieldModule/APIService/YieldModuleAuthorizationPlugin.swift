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
    private let yieldApiKeyProvider = YieldModuleAPIKeyProvider()
    private let tangemApiKeyProvider = TangemAPIKeyProvider()

    func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        var request = request

        guard let yieldTarget = target as? YieldModuleAPITarget else {
            return request
        }

        if yieldTarget.target.isTransactionEvents, let header = tangemApiKeyProvider.getApiKeyHeader() {
            request.headers.add(.init(name: header.name, value: header.value))
            return request
        }

        if let header = yieldApiKeyProvider.getApiKeyHeader(for: yieldTarget.yieldModuleAPIType) {
            request.headers.add(header)
            return request
        }

        assertionFailure("Yield Module API key is empty — header not added")
        return request
    }
}
