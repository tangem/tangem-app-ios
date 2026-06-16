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
        case getTransactionsForAddress(
            address: String,
            limit: Int,
            paginationToken: String?,
            tokenAccountsFilter: TokenAccountsFilter
        )

        var id: Int { 1 }

        var method: String {
            switch self {
            case .getTransactionsForAddress:
                return "getTransactionsForAddress"
            }
        }

        var params: (any Encodable)? {
            switch self {
            case .getTransactionsForAddress(let address, let limit, let paginationToken, let tokenAccountsFilter):
                return [
                    AnyEncodable(address),
                    AnyEncodable(GetTransactionsConfig(
                        limit: limit,
                        paginationToken: paginationToken,
                        tokenAccountsFilter: tokenAccountsFilter
                    )),
                ]
            }
        }

        enum TokenAccountsFilter {
            case `default`
            case balanceChanged
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
    private struct GetTransactionsConfig: Encodable {
        let transactionDetails: String = "full"
        let sortOrder: String = "desc"
        let commitment: String = "finalized"
        let encoding: String = "jsonParsed"
        let maxSupportedTransactionVersion: Int = 0
        let limit: Int
        let paginationToken: String?
        let filters: GetTransactionsFilters?

        init(
            limit: Int,
            paginationToken: String?,
            tokenAccountsFilter: Request.TokenAccountsFilter
        ) {
            self.limit = limit
            self.paginationToken = paginationToken
            filters = GetTransactionsFilters(tokenAccountsFilter: tokenAccountsFilter)
        }
    }

    private struct GetTransactionsFilters: Encodable {
        let tokenAccounts: String

        init?(tokenAccountsFilter: Request.TokenAccountsFilter) {
            switch tokenAccountsFilter {
            case .default:
                return nil
            case .balanceChanged:
                tokenAccounts = "balanceChanged"
            }
        }
    }
}

extension SolanaTransactionHistoryTarget: TargetTypeLogConvertible {
    var requestDescription: String {
        request.method
    }

    var shouldLogResponseBody: Bool { true }
}
