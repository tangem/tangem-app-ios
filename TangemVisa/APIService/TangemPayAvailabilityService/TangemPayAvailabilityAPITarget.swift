//
//  TangemPayAvailabilityAPITarget.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemNetworkUtils
import Moya

struct TangemPayAvailabilityAPITarget: TargetType {
    let target: Target
    let apiType: VisaAPIType

    var baseURL: URL {
        apiType.bffBaseURL
    }

    var path: String {
        switch target {
        case .getEligibility:
            return "customer/eligibility"
        case .validateDeeplink:
            return "deeplink/validate"
        }
    }

    var method: Moya.Method {
        switch target {
        case .getEligibility:
            return .get
        case .validateDeeplink:
            return .post
        }
    }

    var task: Moya.Task {
        switch target {
        case .getEligibility:
            return .requestPlain
        case .validateDeeplink(let deeplinkString):
            let requestData = ValidateDeeplinkRequest(link: deeplinkString)
            return .requestJSONEncodable(requestData)
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
        case validateDeeplink(deeplinkString: String)
    }
}

extension TangemPayAvailabilityAPITarget: TargetTypeLogConvertible {
    var requestDescription: String {
        path
    }

    var shouldLogResponseBody: Bool {
        return false
    }
}
