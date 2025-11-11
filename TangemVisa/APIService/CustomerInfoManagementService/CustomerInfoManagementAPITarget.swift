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
            "customer/me"
        case .getKYCAccessToken:
            "customer/kyc"
        case .getBalance:
            "customer/balance"
        case .getCardDetails:
            "customer/card/details"
        case .freeze:
            "customer/card/freeze"
        case .unfreeze:
            "customer/card/unfreeze"
        case .getTransactionHistory:
            "customer/transactions"
        case .placeOrder:
            "order"
        case .getOrder(let orderId):
            "order/\(orderId)"
        }
    }

    var method: Moya.Method {
        switch target {
        case .getCustomerInfo,
             .getKYCAccessToken,
             .getOrder,
             .getBalance,
             .getTransactionHistory:
            .get

        case .placeOrder,
             .getCardDetails,
             .freeze,
             .unfreeze:
            .post
        }
    }

    var task: Moya.Task {
        switch target {
        case .getCustomerInfo,
             .getKYCAccessToken,
             .getOrder,
             .getBalance:
            return .requestPlain

        case .freeze(let cardId), .unfreeze(let cardId):
            let requestData = TangemPayFreezeUnfreezeRequest(cardId: cardId)
            return .requestJSONEncodable(requestData)

        case .getTransactionHistory(let limit, let cursor):
            var requestParams = [
                "limit": "\(limit)",
            ]
            if let cursor {
                requestParams["cursor"] = cursor
            }
            return .requestParameters(parameters: requestParams, encoding: URLEncoding.default)

        case .getCardDetails(let sessionId):
            let requestData = TangemPayCardDetailsRequest(sessionId: sessionId)
            return .requestJSONEncodable(requestData)

        case .placeOrder(let walletAddress):
            let requestData = TangemPayPlaceOrderRequest(walletAddress: walletAddress)
            return .requestJSONEncodable(requestData)
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
        case getCustomerInfo

        /// Retrieves an access token for the SumSub KYC flow
        case getKYCAccessToken

        case getBalance
        case getCardDetails(sessionId: String)
        case freeze(cardId: String)
        case unfreeze(cardId: String)

        case getTransactionHistory(limit: Int, cursor: String?)

        case placeOrder(walletAddress: String)
        case getOrder(orderId: String)
    }
}
