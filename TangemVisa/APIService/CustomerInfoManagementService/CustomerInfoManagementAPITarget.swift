//
//  CustomerInfoManagementAPITarget.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct CustomerInfoManagementAPITarget: TargetType {
    let authorizationToken: String
    let target: Target
    let apiType: VisaAPIType

    var baseURL: URL {
        apiType.baseURL
    }

    var path: String {
        switch target {
        case .getCustomerInfo:
            return "customer/payment_account"
        }
    }

    var method: Moya.Method {
        switch target {
        case .getCustomerInfo: return .get
        }
    }

    var task: Moya.Task {
        switch target {
        case .getCustomerInfo(let productInstanceId):
            let params = [
                "product_instance_id": productInstanceId,
            ]
            return .requestParameters(parameters: params, encoding: URLEncoding())
        }
    }

    var headers: [String: String]? {
        var defaultHeaders = VisaConstants.defaultHeaderParams
        defaultHeaders[VisaConstants.authorizationHeaderKey] = authorizationToken

        return defaultHeaders
    }
}

extension CustomerInfoManagementAPITarget {
    enum Target {
        /// Load all available customer info. Can be used for loading data about payment account address
        /// Will be updated later, not fully implemented on BFF
        case getCustomerInfo(productInstanceId: String)
    }
}
