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
    case healthCheck
}

extension HealthCheckTarget: TargetType {
    var baseURL: URL {
        OneInchBaseTarget.swappingBaseURL
    }

    var path: String {
        switch self {
        case .healthCheck:
            return "/healthcheck"
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
