//
//  TransactionHistoryAPITarget.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemNetworkUtils
import Moya

struct TransactionHistoryAPITarget: TargetType {
    let target: Target
    let apiType: VisaAPIType

    var baseURL: URL {
        apiType.baseURL.appendingPathComponent("customer/")
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
            var requestParams: [String: String] = [
                VisaConstants.productInstanceIdKey: request.productInstanceId,
                ParameterKey.offset.rawValue: "\(request.offset)",
                ParameterKey.limit.rawValue: "\(request.numberOfItems)",
            ]
            if let cardId = request.cardId {
                requestParams[VisaConstants.cardIdKey] = cardId
            }
            return .requestParameters(parameters: requestParams, encoding: URLEncoding.default)
        }
    }

    var headers: [String: String]? {
        ["Content-Type": "application/json"]
    }
}

extension TransactionHistoryAPITarget {
    enum Target {
        /// Will be updated later, not implemented on BFF
        case txHistoryPage(request: VisaTransactionHistoryDTO.APIRequest)
    }
}

extension TransactionHistoryAPITarget {
    enum ParameterKey: String {
        case offset
        case limit
    }
}

extension TransactionHistoryAPITarget: TargetTypeLogConvertible {
    var requestDescription: String {
        path
    }

    var shouldLogResponseBody: Bool {
        return false
    }
}
