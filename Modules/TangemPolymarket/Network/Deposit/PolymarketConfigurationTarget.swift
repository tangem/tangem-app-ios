//
//  PolymarketConfigurationTarget.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemNetworkUtils

struct PolymarketConfigurationTarget: Moya.TargetType {
    let environment: PolymarketBFFEnvironment
    let walletId: String

    var baseURL: URL { environment.baseURL }
    var headers: [String: String]? { environment.requestHeaders(walletId: walletId) }

    var path: String { "api/predictions/v1/configuration" }
    var method: Moya.Method { .get }
    var task: Moya.Task { .requestPlain }
}

extension PolymarketConfigurationTarget: TargetTypeLogConvertible {
    var requestDescription: String { path }
    var shouldLogResponseBody: Bool { false }
}
