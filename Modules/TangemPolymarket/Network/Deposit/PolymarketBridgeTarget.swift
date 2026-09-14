//
//  PolymarketBridgeTarget.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemNetworkUtils

struct PolymarketBridgeTarget: Moya.TargetType {
    let baseURL: URL
    let target: Target

    enum Target {
        case supportedAssets
        case fundingAddresses(PolymarketDTO.DepositRequest, builderCode: String)
        case withdrawAddresses(PolymarketDTO.BridgeWithdrawRequest, builderCode: String)
    }

    var path: String {
        switch target {
        case .supportedAssets: "supported-assets"
        case .fundingAddresses: "deposit"
        case .withdrawAddresses: "withdraw"
        }
    }

    var method: Moya.Method {
        switch target {
        case .supportedAssets: .get
        case .fundingAddresses, .withdrawAddresses: .post
        }
    }

    var task: Moya.Task {
        switch target {
        case .supportedAssets:
            return .requestPlain
        case .fundingAddresses(let request, _):
            return .requestJSONEncodable(request)
        case .withdrawAddresses(let request, _):
            return .requestJSONEncodable(request)
        }
    }

    var headers: [String: String]? {
        switch target {
        case .supportedAssets:
            return nil
        case .fundingAddresses(_, let builderCode), .withdrawAddresses(_, let builderCode):
            return [Constants.builderCodeHeader: builderCode]
        }
    }
}

// MARK: - Constants

private extension PolymarketBridgeTarget {
    enum Constants {
        static let builderCodeHeader = "X-Builder-Code"
    }
}

extension PolymarketBridgeTarget: TargetTypeLogConvertible {
    var requestDescription: String { path }
    var shouldLogResponseBody: Bool { false }
}
