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
        case .isPaeraCustomer(let customerWalletId):
            return "customer/wallets/\(customerWalletId)"
        }
    }

    var method: Moya.Method {
        switch target {
        case .getEligibility, .isPaeraCustomer:
            return .get
        case .validateDeeplink:
            return .post
        }
    }

    var task: Moya.Task {
        switch target {
        case .getEligibility, .isPaeraCustomer:
            return .requestPlain
        case .validateDeeplink(let deeplinkString):
            let requestData = ValidateDeeplinkRequest(link: deeplinkString)
            return .requestJSONEncodable(requestData)
        }
    }

    var headers: [String: String]? {
        nil
    }
}

extension TangemPayAvailabilityAPITarget {
    enum Target {
        /// Checks Tangem Pay offer availability for user
        case getEligibility
        case validateDeeplink(deeplinkString: String)
        case isPaeraCustomer(customerWalletId: String)
    }
}

extension TangemPayAvailabilityAPITarget: TargetTypeLogConvertible {
    var requestDescription: String {
        path
    }

    var shouldLogResponseBody: Bool {
        false
    }
}
