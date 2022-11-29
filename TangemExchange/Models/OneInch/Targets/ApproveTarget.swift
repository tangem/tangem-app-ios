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
    case spender(blockchain: ExchangeBlockchain)
    case transaction(blockchain: ExchangeBlockchain, params: ApproveTransactionParameters)
    case allowance(blockchain: ExchangeBlockchain, params: ApproveAllowanceParameters)
}

extension ApproveTarget: TargetType {
    var baseURL: URL {
        Constants.exchangeAPIBaseURL
    }

    var path: String {
        switch self {
        case .spender(let blockchain):
            return "/\(blockchain.chainId)/approve/spender"
        case .transaction(let blockchain, _):
            return "/\(blockchain.chainId)/approve/transaction"
        case .allowance(let blockchain, _):
            return "/\(blockchain.chainId)/approve/allowance"
        }
    }

    var method: Moya.Method { return .get }

    var task: Task {
        switch self {
        case .spender:
            return .requestPlain
        case .transaction(_, let params):
            return .requestParameters(params)
        case .allowance(_, let params):
            return .requestParameters(params)
        }
    }

    var headers: [String: String]? {
        nil
    }
}
