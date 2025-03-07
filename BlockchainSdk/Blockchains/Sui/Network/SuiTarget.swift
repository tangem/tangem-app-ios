//
// SuiTarget.swift
// BlockchainSdk
//
// Created by [REDACTED_AUTHOR]
// Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemNetworkUtils

struct SuiTarget: TargetType {
    let baseURL: URL
    let request: SuiTarget.Request

    var path: String {
        ""
    }

    var method: Moya.Method {
        .post
    }

    var task: Moya.Task {
        .requestJSONRPC(id: request.id, method: request.method, params: request.params)
    }

    var headers: [String: String]?
}

extension SuiTarget {
    enum Request {
        case getBalance(address: String, cursor: String?)
        case getReferenceGasPrice
        case dryRunTransaction(transaction: String)
        case sendTransaction(transaction: String, signature: String)

        var id: Int { 1 }

        var method: String {
            switch self {
            case .getBalance:
                return "suix_getAllCoins"
            case .getReferenceGasPrice:
                return "suix_getReferenceGasPrice"
            case .dryRunTransaction:
                return "sui_dryRunTransactionBlock"
            case .sendTransaction:
                return "sui_executeTransactionBlock"
            }
        }

        var params: (any Encodable)? {
            switch self {
            case .getBalance(let address, let cursor):
                return [address, cursor]
            case .getReferenceGasPrice:
                return nil
            case .dryRunTransaction(let transaction):
                return [transaction]
            case .sendTransaction(let transaction, let signature):
                return [AnyEncodable(transaction), AnyEncodable([signature])]
            }
        }
    }
}

extension SuiTarget: TargetTypeLogConvertible {
    var requestDescription: String {
        request.method
    }
}
