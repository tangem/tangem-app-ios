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
    let target: TargetType

    enum TargetType {
        case markets(chains: [String]?)
        case token(tokenContractAddress: String, chainId: Int)
        case chart(tokenContractAddress: String, chainId: Int, window: String?, bucketSizeDays: Int?)
    }

    var baseURL: URL {
        switch yieldModuleAPIType {
        case .develop:
            return URL(string: "https://yield.tests-d.com/api/v1")!
        case .production:
            return URL(string: "https://yield.tests-d.com/api/v1")!
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
        }
    }

    var method: Moya.Method {
        switch target {
        case .markets, .token, .chart:
            return .get
        }
    }

    var task: Moya.Task {
        switch target {
        case .markets(.some(let chains)):
            return .requestParameters(chains, encoding: URLEncoding(destination: .queryString, arrayEncoding: .brackets))
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
        }
    }

    var headers: [String: String]? {
        switch target {
        case .markets, .token, .chart:
            return nil
        }
    }
}

enum YieldModuleAPIType {
    case develop
    case production

    public var title: String {
        switch self {
        case .develop:
            return "dev"
        case .production:
            return "prod"
        }
    }
}
