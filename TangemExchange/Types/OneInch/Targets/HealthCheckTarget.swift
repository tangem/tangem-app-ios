//
//  HealthCheckTarget.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Moya
import Foundation

/// Check 1inch service status
enum HealthCheckTarget {
    case healthCheck(blockchain: ExchangeBlockchain)
}

extension HealthCheckTarget: TargetType {
    var baseURL: URL {
        Constants.exchangeAPIBaseURL
    }

    var path: String {
        switch self {
        case .healthCheck(let exchangeBlockchain):
            return "/\(exchangeBlockchain.id)/healthcheck"
        }
    }

    var method: Moya.Method {
        return .get
    }

    var task: Task {
        return .requestPlain
    }

    var headers: [String: String]? {
        return nil
    }
}
