//
//  SolanaScaledUiAmountTarget.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation
import Moya
import SolanaSwift
import TangemNetworkUtils
import struct AnyCodable.AnyEncodable

struct SolanaScaledUiAmountTarget {
    let endpoint: RPCEndpoint
    let request: Request
}

extension SolanaScaledUiAmountTarget {
    enum Request {
        case getAccountInfo(mintAddress: String)

        var id: Int { 1 }

        var method: String {
            switch self {
            case .getAccountInfo:
                return "getAccountInfo"
            }
        }

        var params: (any Encodable)? {
            switch self {
            case .getAccountInfo(let mintAddress):
                return [
                    AnyEncodable(mintAddress),
                    AnyEncodable(GetAccountInfoConfiguration()),
                ]
            }
        }
    }
}

extension SolanaScaledUiAmountTarget: TargetType {
    var baseURL: URL {
        endpoint.url
    }

    var path: String { "" }

    var method: Moya.Method { .post }

    var task: Moya.Task {
        .requestJSONRPC(id: request.id, method: request.method, params: request.params)
    }

    var headers: [String: String]? {
        var headers = [
            "Accept": "application/json",
            "Content-Type": "application/json",
        ]

        if let name = endpoint.apiKeyHeaderName, let value = endpoint.apiKeyHeaderValue {
            headers[name] = value
        }

        return headers
    }
}

private extension SolanaScaledUiAmountTarget {
    struct GetAccountInfoConfiguration: Encodable {
        let encoding: String = "jsonParsed"
    }
}
