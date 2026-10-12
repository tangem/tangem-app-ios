//
//  PolymarketWithdrawTarget.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemNetworkUtils

struct PolymarketWithdrawTarget: Moya.TargetType {
    let environment: PolymarketBFFEnvironment
    let walletId: String
    let target: Target

    var baseURL: URL { environment.baseURL }
    var headers: [String: String]? { environment.requestHeaders(walletId: walletId) }

    enum Target {
        case submit(PolymarketDTO.RelayedBatchRequest)
        case record(transactionId: String)
    }

    var path: String {
        switch target {
        case .submit: Constants.withdrawPath
        case .record(let transactionId): "\(Constants.withdrawPath)/\(transactionId)"
        }
    }

    var method: Moya.Method {
        switch target {
        case .submit: .post
        case .record: .get
        }
    }

    var task: Moya.Task {
        switch target {
        case .submit(let request): .requestJSONEncodable(request)
        case .record: .requestPlain
        }
    }
}

// MARK: - Constants

private extension PolymarketWithdrawTarget {
    enum Constants {
        static let withdrawPath = "api/predictions/v1/withdraw"
    }
}

extension PolymarketWithdrawTarget: TargetTypeLogConvertible {
    var requestDescription: String { path }
    var shouldLogResponseBody: Bool { false }
}
