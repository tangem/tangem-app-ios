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
    @Injected(\.keysManager) private var keysManager: KeysManager

    func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        var request = request

        let apiKey = keysManager.yieldModuleApiKey

        if !apiKey.isEmpty {
            request.headers.add(name: "api-key", value: apiKey)
        } else {
            assertionFailure("Yield Module API key is empty — header not added")
        }

        return request
    }
}
