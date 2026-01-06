//
//  GaslessTransactionsAuthorizationPlugin.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct GaslessTransactionsAuthorizationPlugin: PluginType {
    private let gaslessTransactionsKeyProvider = GaslessTransactionsAPIKeyProvider()

    func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        var request = request

        if let header = gaslessTransactionsKeyProvider.getApiKeyHeader() {
            request.headers.add(header)
            return request
        }

        // [REDACTED_TODO_COMMENT]
        // assertionFailure("Gasless Transactions API key is empty — header not added")
        return request
    }
}
