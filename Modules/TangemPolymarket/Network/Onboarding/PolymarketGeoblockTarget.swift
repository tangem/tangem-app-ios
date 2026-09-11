//
//  PolymarketGeoblockTarget.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemNetworkUtils

struct PolymarketGeoblockTarget: Moya.TargetType {
    let baseURL: URL

    var path: String { "api/geoblock" }
    var method: Moya.Method { .get }
    var task: Moya.Task { .requestPlain }
    var headers: [String: String]? { nil }
}

extension PolymarketGeoblockTarget: TargetTypeLogConvertible {
    var requestDescription: String { path }
    var shouldLogResponseBody: Bool { false }
}
