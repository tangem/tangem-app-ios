//
//  MoyaProvider+AsyncRequest.swift
//  TangemNetworkUtils
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Moya
import TangemFoundation

public extension MoyaProvider {
    @available(iOS, deprecated: 100000.0, renamed: "request(_:)")
    func asyncRequest(_ target: Target) async throws -> Response {
        try await requestPublisher(target).async()
    }
}
