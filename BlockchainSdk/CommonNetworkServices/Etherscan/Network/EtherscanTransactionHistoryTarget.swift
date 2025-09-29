//
//  EtherscanTransactionHistoryTarget.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemNetworkUtils

struct EtherscanTransactionHistoryTarget {
    let configuration: Configuration
    let target: Target
}

// MARK: - Auxiliary types

extension EtherscanTransactionHistoryTarget {
    enum Configuration {
        case etherscan(chainId: Int, apiKey: String)
    }

    enum Target {
        case getCoinTransactionHistory(address: String, page: Int, limit: Int)
        case getTokenTransactionHistory(address: String, contract: String, page: Int, limit: Int)
    }
}

// MARK: - TargetType protocol conformance

extension EtherscanTransactionHistoryTarget: TargetType {
    var baseURL: URL {
        switch configuration {
        case .etherscan:
            return URL(string: "https://api.etherscan.io/v2")!
        }
    }

    var path: String {
        switch configuration {
        case .etherscan:
            return "api"
        }
    }

    var method: Moya.Method {
        switch configuration {
        case .etherscan:
            return .get
        }
    }

    var task: Moya.Task {
        switch configuration {
        case .etherscan(let chainId, let apiKey):
            var parameters: [String: Any] = [
                "module": "account",
                "startblock": 0,
                "endblock": 99999999,
                "sort": "desc",
                "chainid": chainId,
            ]

            parameters["apikey"] = apiKey

            switch target {
            case .getCoinTransactionHistory(let address, let page, let limit):
                parameters["action"] = "txlist"
                parameters["address"] = address
                parameters["page"] = page
                parameters["offset"] = limit

                return .requestParameters(
                    parameters: parameters,
                    encoding: URLEncoding.queryString
                )
            case .getTokenTransactionHistory(let address, let contract, let page, let limit):
                parameters["action"] = "tokentx"
                parameters["address"] = address
                parameters["contractaddress"] = contract
                parameters["page"] = page
                parameters["offset"] = limit

                return .requestParameters(
                    parameters: parameters,
                    encoding: URLEncoding.queryString
                )
            }
        }
    }

    var headers: [String: String]? {
        return [
            "Content-Type": "application/json",
            "Accept": "application/json",
        ]
    }
}

extension EtherscanTransactionHistoryTarget: TargetTypeLogConvertible {
    var requestDescription: String {
        path
    }

    var shouldLogResponseBody: Bool {
        false
    }
}
