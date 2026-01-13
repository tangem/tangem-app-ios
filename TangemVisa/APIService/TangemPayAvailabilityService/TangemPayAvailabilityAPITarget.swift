//
//  TangemPayAvailabilityAPITarget.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemNetworkUtils
import TangemPay

struct TangemPayAvailabilityAPITarget: TargetType {
    let target: Target
    let apiType: TangemPayAPIType

    var baseURL: URL {
        apiType.bffBaseURL
    }

    var path: String {
        switch target {
        case .getEligibility:
            return "customer/eligibility"
        case .validateDeeplink:
            return "deeplink/validate"
        case .isPaeraCustomer(let customerWalletId, _):
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
        switch target {
        case .isPaeraCustomer(_, let bffStaticToken):
            [Constants.apiKeyHeaderName: bffStaticToken]
        case .getEligibility, .validateDeeplink:
            nil
        }
    }
}

extension TangemPayAvailabilityAPITarget {
    enum Target {
        /// Checks Tangem Pay offer availability for user
        case getEligibility
        case validateDeeplink(deeplinkString: String)
        case isPaeraCustomer(customerWalletId: String, bffStaticToken: String)
    }

    enum Constants {
        static let apiKeyHeaderName = "X-API-KEY"
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
