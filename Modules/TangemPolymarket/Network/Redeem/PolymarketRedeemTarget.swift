//
//  PolymarketRedeemTarget.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemNetworkUtils

struct PolymarketRedeemTarget: Moya.TargetType {
    let environment: PolymarketBFFEnvironment
    let walletId: String
    let target: Target

    var baseURL: URL { environment.baseURL }
    var headers: [String: String]? { environment.requestHeaders(walletId: walletId) }

    enum Target {
        case call(conditionId: String, isNegRisk: Bool)
        case submit(PolymarketDTO.RelayedBatchRequest)
        case record(transactionId: String)
    }

    var path: String {
        switch target {
        case .call: "\(Constants.redeemPath)/call"
        case .submit: Constants.redeemPath
        case .record(let transactionId): "\(Constants.redeemPath)/\(transactionId)"
        }
    }

    var method: Moya.Method {
        switch target {
        case .call, .record: .get
        case .submit: .post
        }
    }

    var task: Moya.Task {
        switch target {
        case .call(let conditionId, let isNegRisk):
            .requestParameters(
                parameters: ["conditionId": conditionId, "negRisk": isNegRisk],
                encoding: URLEncoding(boolEncoding: .literal)
            )
        case .submit(let request):
            .requestJSONEncodable(request)
        case .record:
            .requestPlain
        }
    }
}

// MARK: - Constants

private extension PolymarketRedeemTarget {
    enum Constants {
        static let redeemPath = "api/predictions/v1/positions/redeem"
    }
}

extension PolymarketRedeemTarget: TargetTypeLogConvertible {
    var requestDescription: String { path }
    var shouldLogResponseBody: Bool { false }
}
