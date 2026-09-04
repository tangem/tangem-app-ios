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
    let baseURL: URL
    let environmentHeaders: [String: String]
    let walletId: String

    var path: String { "api/predictions/v1/configuration" }
    var method: Moya.Method { .get }
    var task: Moya.Task { .requestPlain }

    var headers: [String: String]? {
        var headers = environmentHeaders
        headers[Constants.walletIdHeader] = walletId
        return headers
    }
}

// MARK: - Constants

private extension PolymarketConfigurationTarget {
    enum Constants {
        static let walletIdHeader = "wallet-id"
    }
}

extension PolymarketConfigurationTarget: TargetTypeLogConvertible {
    var requestDescription: String { path }
    var shouldLogResponseBody: Bool { false }
}
