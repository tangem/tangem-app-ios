//
//  SolanaTransactionHistoryTarget.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemFoundation
import TangemNetworkUtils
import struct AnyCodable.AnyEncodable

struct SolanaTransactionHistoryTarget {
    let configuration: Configuration
    let request: Request
}

extension SolanaTransactionHistoryTarget {
    enum Configuration {
        case alchemy(apiKey: String)
    }

    enum Request {
        case getTokenAccountsByOwner(owner: String, mint: String)
        case getSignaturesForAddress(address: String, limit: Int, before: String?)
        case getTransaction(signature: String)

        var id: Int { 1 }

        var method: String {
            switch self {
            case .getTokenAccountsByOwner:
                return "getTokenAccountsByOwner"
            case .getSignaturesForAddress:
                return "getSignaturesForAddress"
            case .getTransaction:
                return "getTransaction"
            }
        }

        var params: (any Encodable)? {
            switch self {
            case .getTokenAccountsByOwner(let owner, let mint):
                return [
                    AnyEncodable(owner),
                    AnyEncodable(GetTokenAccountsFilter(mint: mint)),
                    AnyEncodable(JsonParsedEncodingConfig()),
                ]
            case .getSignaturesForAddress(let address, let limit, let before):
                return [
                    AnyEncodable(address),
                    AnyEncodable(GetSignaturesConfig(limit: limit, before: before)),
                ]
            case .getTransaction(let signature):
                return [
                    AnyEncodable(signature),
                    AnyEncodable(GetTransactionConfig()),
                ]
            }
        }
    }
}

extension SolanaTransactionHistoryTarget: TargetType {
    var baseURL: URL {
        switch configuration {
        case .alchemy:
            return URL(string: "https://solana-mainnet.g.alchemy.com/")!
        }
    }

    var path: String {
        switch configuration {
        case .alchemy(let apiKey):
            return "v2/\(apiKey)"
        }
    }

    var method: Moya.Method { .post }

    var task: Moya.Task {
        .requestJSONRPC(id: request.id, method: request.method, params: request.params)
    }

    var headers: [String: String]? {
        [
            "Accept": "application/json",
            "Content-Type": "application/json",
        ]
    }
}

extension SolanaTransactionHistoryTarget {
    private struct GetTokenAccountsFilter: Encodable {
        let mint: String
    }

    private struct JsonParsedEncodingConfig: Encodable {
        let encoding: String = "jsonParsed"
    }

    private struct GetSignaturesConfig: Encodable {
        let commitment: String = "finalized"
        let limit: Int
        let before: String?
    }

    private struct GetTransactionConfig: Encodable {
        let encoding: String = "jsonParsed"
        let maxSupportedTransactionVersion: Int = 0
    }
}

extension SolanaTransactionHistoryTarget: TargetTypeLogConvertible {
    var requestDescription: String {
        request.method
    }

    var shouldLogResponseBody: Bool { true }
}
