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
            return "eligibility/channels"
        case .checkEligibility:
            return "eligibility/check"
        case .validateDeeplink:
            return "deeplink/validate"
        case .isPaeraCustomer(let customerWalletId):
            return "customer/wallets/\(customerWalletId)"
        case .getImages:
            return "images"
        }
    }

    var method: Moya.Method {
        switch target {
        case .getEligibility, .checkEligibility, .isPaeraCustomer, .getImages:
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
        case .getImages(let deeplinkValue):
            let requestData = TangemPayImagesRequest(deeplinkValue: deeplinkValue)
            return .requestParameters(requestData)
        case .checkEligibility(let product, let country, let region):
            let requestData = TangemPayEligibilityCheckRequest(product: product, country: country, region: region)
            return .requestParameters(requestData)
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
        case checkEligibility(product: TangemPayProduct, country: String, region: String?)
        case validateDeeplink(deeplinkString: String)
        case isPaeraCustomer(customerWalletId: String)
        case getImages(deeplinkValue: String)
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
