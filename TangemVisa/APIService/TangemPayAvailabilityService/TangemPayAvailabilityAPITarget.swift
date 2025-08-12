//
//  TangemPayAvailabilityAPITarget.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct TangemPayAvailabilityAPITarget: TargetType {
    let target: Target
    let apiType: VisaAPIType

    var baseURL: URL {
        apiType.baseURL
    }

    var path: String {
        switch target {
        case .getEligibility:
            return "customer/eligibility"
        }
    }

    var method: Moya.Method {
        switch target {
        case .getEligibility:
            return .get
        }
    }

    var task: Moya.Task {
        switch target {
        case .getEligibility:
            return .requestPlain
        }
    }

    var headers: [String: String]? {
        [:]
    }
}

extension TangemPayAvailabilityAPITarget {
    enum Target {
        /// Checks Tangem Pay offer availability for user
        case getEligibility
    }
}
