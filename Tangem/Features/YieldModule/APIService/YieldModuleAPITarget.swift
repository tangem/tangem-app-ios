//
//  YieldModuleAPITarget.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct YieldModuleAPITarget: TargetType {
    let yieldModuleAPIType: YieldModuleAPIType
    let tangemAPIType: TangemAPIType
    let target: TargetType

    enum TargetType: Equatable {
        case markets(chains: [String]?)
        case token(tokenContractAddress: String, chainId: Int)
        case chart(tokenContractAddress: String, chainId: Int, window: String?, bucketSizeDays: Int?)
        case activate(tokenContractAddress: String, walletAddress: String, chainId: Int, userWalletId: String)
        case deactivate(tokenContractAddress: String, walletAddress: String, chainId: Int)
        case transactionEvents(txHash: String, operation: String)

        var isTransactionEvents: Bool {
            switch self {
            case .transactionEvents:
                return true
            default:
                return false
            }
        }
    }

    var tangemApiBaseURL: URL {
        tangemAPIType.apiBaseUrl
    }

    var yieldBaseURL: URL {
        switch yieldModuleAPIType {
        case .prod:
            return URL(string: "https://yield.tangem.org/api/v1")!
        case .dev:
            return URL(string: "https://yield.tests-d.com/api/v1")!
        case .stage:
            return URL(string: "https://yield.tests-s.com/api/v1")!
        }
    }

    var baseURL: URL {
        switch target {
        case .markets, .token, .chart, .activate, .deactivate:
            yieldBaseURL
        case .transactionEvents:
            tangemApiBaseURL
        }
    }

    var path: String {
        switch target {
        case .markets:
            return "/yield/markets"
        case .token(let tokenContractAddress, let chainId):
            return "/yield/token/\(chainId)/\(tokenContractAddress)"
        case .chart(let tokenContractAddress, let chainId, _, _):
            return "/yield/token/\(chainId)/\(tokenContractAddress)/chart"
        case .activate:
            return "/module/activate"
        case .deactivate:
            return "/module/deactivate"
        case .transactionEvents:
            return "/transaction-events"
        }
    }

    var method: Moya.Method {
        switch target {
        case .markets, .token, .chart:
            return .get
        case .activate, .deactivate, .transactionEvents:
            return .post
        }
    }

    var task: Moya.Task {
        switch target {
        case .markets(.some(let chains)):
            return .requestParameters(
                ["chainId": chains],
                encoding: URLEncoding(destination: .queryString, arrayEncoding: .noBrackets)
            )
        case .markets(.none), .token:
            return .requestPlain
        case .chart(_, _, let window, let bucketSizeDays):
            var parameters: [String: Any] = [:]
            if let window {
                parameters["window"] = window
            }
            if let bucketSizeDays {
                parameters["bucketSizeDays"] = bucketSizeDays
            }
            return .requestParameters(parameters: parameters, encoding: URLEncoding(destination: .queryString))
        case .activate(let tokenContractAddress, let walletAddress, let chainId, _),
             .deactivate(let tokenContractAddress, let walletAddress, let chainId):
            return .requestParameters(
                parameters: [
                    "tokenAddress": tokenContractAddress,
                    "chainId": chainId,
                    "userAddress": walletAddress,
                ],
                encoding: JSONEncoding.default
            )
        case .transactionEvents(let txHash, let operation):
            return .requestParameters(
                parameters: [
                    "transactionId": txHash,
                    "operationType": operation,
                ],
                encoding: JSONEncoding.default
            )
        }
    }

    var headers: [String: String]? {
        switch target {
        case .activate(_, _, _, let userWalletId):
            return ["userWalletId": "\(userWalletId)"]
        case .markets, .token, .chart, .deactivate, .transactionEvents:
            return nil
        }
    }
}

enum YieldModuleAPIType: String, CaseIterable {
    case dev
    case stage
    case prod

    public var title: String {
        rawValue
    }
}
