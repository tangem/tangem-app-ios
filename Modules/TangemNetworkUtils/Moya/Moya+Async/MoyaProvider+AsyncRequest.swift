//
//  MoyaProvider+AsyncRequest.swift
//  TangemNetworkUtils
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemFoundation

public extension MoyaProvider {
    func asyncRequest(_ target: Target) async throws -> Response {
        try await requestPublisher(target).async()
    }
}
