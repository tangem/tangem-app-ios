//
//  ExpressAuthorizationPlugin.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct ExpressAuthorizationPlugin: PluginType {
    let apiKey: String
    let userId: String
    let sessionId: String
    let refcode: String?
    let batchId: String?
    let isVersionV2: Bool

    func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        var request = request

        if !isVersionV2 {
            request.headers.add(name: "api-key", value: apiKey)
        }
        request.headers.add(name: "user-id", value: userId)
        request.headers.add(name: "session-id", value: sessionId)

        if let refcode {
            request.headers.add(name: "refcode", value: refcode)
        }

        if let batchId, let target = target as? ExpressAPITarget, target.carriesBatchId {
            request.headers.add(name: "batch-id", value: batchId)
        }

        return request
    }
}
