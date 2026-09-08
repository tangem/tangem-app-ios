//
//  Moya.Endpoint+stub.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya

extension Moya.Endpoint {
    static func stub(target: some Moya.TargetType, statusCode: Int, responseBody: String) -> Moya.Endpoint {
        Endpoint(
            url: target.baseURL.appendingPathComponent(target.path).absoluteString,
            sampleResponseClosure: { .networkResponse(statusCode, Data(responseBody.utf8)) },
            method: target.method,
            task: target.task,
            httpHeaderFields: target.headers
        )
    }
}
