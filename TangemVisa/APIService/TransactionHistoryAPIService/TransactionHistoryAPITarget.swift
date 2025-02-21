//
//  TransactionHistoryAPITarget.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct TransactionHistoryAPITarget: TargetType {
    let authorizationHeader: String
    let target: Target

    var baseURL: URL {
        return VisaConstants.bffBaseURL.appendingPathComponent("product_instance/")
    }

    var path: String {
        switch target {
        case .txHistoryPage:
            return "transactions"
        }
    }

    var method: Moya.Method {
        switch target {
        case .txHistoryPage:
            return .get
        }
    }

    var task: Task {
        switch target {
        case .txHistoryPage(let request):
            let requestParams = [
                VisaConstants.customerIdKey: request.customerId,
                VisaConstants.productInstanceIdKey: request.productInstanceId,
                ParameterKey.offset.rawValue: "\(request.offset)",
                ParameterKey.limit.rawValue: "\(request.numberOfItems)",
            ]
            return .requestParameters(parameters: requestParams, encoding: URLEncoding.default)
        }
    }

    var headers: [String: String]? {
        var headers = VisaConstants.defaultHeaderParams
        headers[VisaConstants.authorizationHeaderKey] = authorizationHeader
        return headers
    }
}

extension TransactionHistoryAPITarget {
    enum Target {
        case txHistoryPage(request: VisaTransactionHistoryDTO.APIRequest)
    }
}

extension TransactionHistoryAPITarget {
    enum ParameterKey: String {
        case offset
        case limit
    }
}
