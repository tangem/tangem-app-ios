//
//  HederaTarget.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct HederaTarget {
    let configuration: NodeInfo
    let target: Target
}

// MARK: - Auxiliary types

extension HederaTarget {
    enum Target {
        case getAccounts(publicKey: String)
        case getAccountBalance(accountId: String)
        case getTokens(accountId: String, entitiesLimit: Int)
        case getExchangeRate
        case getTransactionInfo(transactionHash: String)
        case getTokenDetails(tokenAddress: String)
    }
}

// MARK: - TargetType protocol conformance

extension HederaTarget: TargetType {
    var baseURL: URL {
        switch target {
        case .getAccounts,
             .getAccountBalance,
             .getTokens,
             .getExchangeRate,
             .getTransactionInfo,
             .getTokenDetails:
            return configuration.url
        }
    }

    var path: String {
        switch target {
        case .getAccounts:
            return "accounts"
        case .getAccountBalance:
            return "balances"
        case .getTokens(let accountId, _):
            return "accounts/\(accountId)/tokens"
        case .getExchangeRate:
            return "network/exchangerate"
        case .getTransactionInfo(let transactionHash):
            return "transactions/\(transactionHash)"
        case .getTokenDetails(let tokenId):
            return "tokens/\(tokenId)"
        }
    }

    var method: Moya.Method {
        switch target {
        case .getAccounts,
             .getTokens,
             .getExchangeRate,
             .getAccountBalance,
             .getTransactionInfo,
             .getTokenDetails:
            return .get
        }
    }

    var task: Moya.Task {
        switch target {
        case .getAccounts(let publicKey):
            let parameters: [String: Any] = [
                "balance": false,
                "account.publickey": publicKey,
            ]
            return .requestParameters(parameters: parameters, encoding: URLEncoding.tangem)
        case .getAccountBalance(let accountId):
            let parameters: [String: Any] = [
                "account.id": accountId,
            ]
            return .requestParameters(parameters: parameters, encoding: URLEncoding.tangem)
        case .getTokens(_, let entitiesLimit):
            let parameters: [String: Any] = [
                "limit": entitiesLimit,
            ]
            return .requestParameters(parameters: parameters, encoding: URLEncoding.tangem)
        case .getExchangeRate,
             .getTransactionInfo,
             .getTokenDetails:
            return .requestPlain
        }
    }

    var headers: [String: String]? {
        var headers = [
            "Content-Type": "application/json",
            "Accept": "application/json",
        ]

        switch target {
        case .getAccounts,
             .getAccountBalance,
             .getTokens,
             .getExchangeRate,
             .getTransactionInfo,
             .getTokenDetails:
            if let headersKeyInfo = configuration.headers {
                headers[headersKeyInfo.headerName] = headersKeyInfo.headerValue
            }
        }

        return headers
    }
}
