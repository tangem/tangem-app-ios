//
//  ApproveTarget.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Moya

/// Target for getting the address of the 1inch router, getting data for sending permission and getting the set limit for a specific token in the 1inch system
enum ApproveTarget {
    case spender
    case transaction(_ params: ApproveTransactionParameters)
    case allowance(_ params: ApproveAllowanceParameters)
}

extension ApproveTarget: TargetType {
    var baseURL: URL {
        OneInchBaseTarget.swappingBaseURL
    }

    var path: String {
        switch self {
        case .spender:
            return "/approve/spender"
        case .transaction:
            return "/approve/transaction"
        case .allowance:
            return "/approve/allowance"
        }
    }

    var method: Moya.Method { .get }

    var task: Task {
        switch self {
        case .spender:
            return .requestPlain
        case .transaction(let params):
            return .requestParameters(params)
        case .allowance(let params):
            return .requestParameters(params)
        }
    }

    var headers: [String: String]? {
        nil
    }
}
