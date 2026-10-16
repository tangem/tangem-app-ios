//
//  PolymarketPositionsValueTarget.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemNetworkUtils

struct PolymarketPositionsValueTarget: Moya.TargetType {
    let baseURL: URL
    let depositWalletAddress: String

    var path: String { "v2/value" }
    var method: Moya.Method { .get }

    var task: Moya.Task {
        .requestParameters(
            parameters: [Constants.userKey: depositWalletAddress],
            encoding: URLEncoding.queryString
        )
    }

    var headers: [String: String]? { nil }
}

private extension PolymarketPositionsValueTarget {
    enum Constants {
        static let userKey = "user"
    }
}

extension PolymarketPositionsValueTarget: TargetTypeLogConvertible {
    var requestDescription: String { path }
    var shouldLogResponseBody: Bool { false }
}
