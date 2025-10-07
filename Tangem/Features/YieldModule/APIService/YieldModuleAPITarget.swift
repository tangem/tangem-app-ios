//
//  APITarget.swift
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
        case yieldMarkets(chains: [String]?)
        case yieldToken(tokenContractAddress: String, chainId: Int)
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
        case .yieldMarkets:
            return "/yield/markets"
        case .yieldToken(let tokenContractAddress, let chainId):
            return "/yield/token/\(chainId)/\(tokenContractAddress)"
        }
    }

    var method: Moya.Method {
        switch target {
        case .yieldMarkets,
             .yieldToken:
            return .get
        }
    }

    var task: Moya.Task {
        switch target {
        case .yieldMarkets(.some(let chains)):
            return .requestParameters(chains, encoding: URLEncoding(destination: .queryString, arrayEncoding: .brackets))
        case .yieldMarkets(.none), .yieldToken:
            return .requestPlain
        }
    }

    var headers: [String: String]? {
        switch target {
        case .yieldMarkets,
             .yieldToken:
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
