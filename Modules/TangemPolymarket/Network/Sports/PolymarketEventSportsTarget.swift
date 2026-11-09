//
//  PolymarketEventSportsTarget.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemNetworkUtils

struct PolymarketEventSportsTarget: Moya.TargetType {
    let baseURL: URL
    let eventSlug: String

    var path: String { "events/slug/\(eventSlug)" }
    var method: Moya.Method { .get }
    var task: Moya.Task { .requestPlain }
    var headers: [String: String]? { nil }
}

extension PolymarketEventSportsTarget: TargetTypeLogConvertible {
    var requestDescription: String { path }
    var shouldLogResponseBody: Bool { false }
}
