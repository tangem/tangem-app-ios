//
//  CustomerInfoManagementAPITarget.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemNetworkUtils
import Moya

struct CustomerInfoManagementAPITarget: TargetType {
    let target: Target
    let apiType: VisaAPIType

    var baseURL: URL {
        apiType.bffBaseURL
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
        case .setPin:
            "customer/card/pin"
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

        case .setPin:
            .put
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

        case .setPin(let pin, let sessionId, let iv):
            let requestData = TangemPaySetPinRequest(pin: pin, sessionId: sessionId, iv: iv)
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
        ["Content-Type": "application/json"]
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
        case setPin(pin: String, sessionId: String, iv: String)

        case getTransactionHistory(limit: Int, cursor: String?)

        case placeOrder(walletAddress: String)
        case getOrder(orderId: String)
    }
}

extension CustomerInfoManagementAPITarget: TargetTypeLogConvertible {
    var requestDescription: String {
        baseURL.appendingPathComponent(path).absoluteString
    }

    var shouldLogResponseBody: Bool {
        true
    }
}
