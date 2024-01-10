//
//  ExpressAuthorizationPlugin.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Moya

struct ExpressAuthorizationPlugin: PluginType {
    let apiKey: String
    let userId: String
    let sessionId: String

    func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        var request = request

        request.headers.add(name: "api-key", value: apiKey)
        request.headers.add(name: "user-id", value: userId)
        request.headers.add(name: "session-id", value: sessionId)

        return request
    }
}
