//
//  KaspaTransactionHistoryTarget.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct KaspaTransactionHistoryTarget {
    let type: TargetType
}

extension KaspaTransactionHistoryTarget {
    enum TargetType {
        case getCoinTransactionHistory(address: String, page: Int, limit: Int)
        /// currently not used, will be implemented in [REDACTED_INFO]
        case getTokenTransactionHistory(address: String, contract: String, page: Int, limit: Int)
    }
}

extension KaspaTransactionHistoryTarget: TargetType {
    var baseURL: URL {
        switch type {
        case .getCoinTransactionHistory:
            URL(string: "https://api.kaspa.org/")!
        case .getTokenTransactionHistory:
            URL(string: "https://api.kasplex.org/v1/")!
        }
    }

    var path: String {
        switch type {
        case .getCoinTransactionHistory(let address, _, _):
            "addresses/\(address)/full-transactions"
        case .getTokenTransactionHistory:
            "krc20/oplist"
        }
    }

    var method: Moya.Method {
        switch type {
        case .getCoinTransactionHistory, .getTokenTransactionHistory: .get
        }
    }

    var task: Moya.Task {
        switch type {
        case .getCoinTransactionHistory(_, let page, let limit):
            .requestParameters(
                parameters: [
                    "limit": limit,
                    "offset": page * limit, // assume limit is constant across calls
                    "resolve_previous_outpoints": "light",
                ],
                encoding: URLEncoding()
            )
        case .getTokenTransactionHistory(let address, _, _, _):
            .requestParameters(parameters: ["address": address], encoding: URLEncoding())
        }
    }

    var headers: [String: String]? {
        nil
    }
}
