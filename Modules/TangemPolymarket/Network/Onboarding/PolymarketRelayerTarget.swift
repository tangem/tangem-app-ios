//
//  PolymarketRelayerTarget.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemNetworkUtils

struct PolymarketRelayerTarget: Moya.TargetType {
    let baseURL: URL
    let ownerAddress: String

    var path: String { "nonce" }
    var method: Moya.Method { .get }

    var task: Moya.Task {
        .requestParameters(
            parameters: ["address": ownerAddress, "type": Constants.walletType],
            encoding: URLEncoding.queryString
        )
    }

    var headers: [String: String]? { nil }
}

private extension PolymarketRelayerTarget {
    enum Constants {
        static let walletType = "WALLET"
    }
}

extension PolymarketRelayerTarget: TargetTypeLogConvertible {
    var requestDescription: String { path }
    var shouldLogResponseBody: Bool { false }
}
