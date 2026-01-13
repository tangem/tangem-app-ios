//
//  TangemPayCustomerAPITarget.swift
//  TangemPay
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemNetworkUtils

struct TangemPayCustomerAPITarget: TargetType {
    let target: Target
    let apiType: TangemPayAPIType
    let encoder: JSONEncoder

    init(target: Target, apiType: TangemPayAPIType, encoder: JSONEncoder) {
        self.target = target
        self.apiType = apiType
        self.encoder = encoder
    }

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
        case .getWithdrawSignableData:
            "customer/card/withdraw/data"
        case .sendWithdrawTransaction:
            "customer/card/withdraw"
        case .placeOrder:
            "order"
        case .getOrder(let orderId):
            "order/\(orderId)"
        case .getPin:
            "customer/card/pin"
        case .setPayEnabled:
            "customer/pay-enabled"
        }
    }

    var method: Moya.Method {
        switch target {
        case .getCustomerInfo,
             .getKYCAccessToken,
             .getOrder,
             .getBalance,
             .getTransactionHistory,
             .getPin:
            .get

        case .placeOrder,
             .getCardDetails,
             .freeze,
             .unfreeze,
             .getWithdrawSignableData,
             .sendWithdrawTransaction:
            .post

        case .setPayEnabled:
            .patch

        case .setPin:
            .put
        }
    }

    var task: Moya.Task {
        switch target {
        case .getCustomerInfo,
             .getKYCAccessToken,
             .getOrder,
             .getBalance,
             .getPin:
            return .requestPlain

        case .setPayEnabled:
            let requestData = TangemPaySetPayEnabledRequest()
            return .requestJSONEncodable(requestData)

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

        case .getWithdrawSignableData(let request):
            return .requestCustomJSONEncodable(request, encoder: encoder)

        case .sendWithdrawTransaction(let request):
            return .requestCustomJSONEncodable(request, encoder: encoder)

        case .getCardDetails(let sessionId):
            let requestData = TangemPayCardDetailsRequest(sessionId: sessionId)
            return .requestJSONEncodable(requestData)

        case .placeOrder(let customerWalletAddress):
            let requestData = TangemPayPlaceOrderRequest(customerWalletAddress: customerWalletAddress)
            return .requestJSONEncodable(requestData)
        }
    }

    var headers: [String: String]? {
        switch target {
        case .getPin(let sessionId):
            ["X-Session-Id": "\(sessionId)"]
        default:
            nil
        }
    }
}

extension TangemPayCustomerAPITarget {
    enum Target {
        /// Load all available customer info. Can be used for loading data about payment account address
        /// Will be updated later, not fully implemented on BFF
        case getCustomerInfo

        /// Retrieves an access token for the SumSub KYC flow
        case getKYCAccessToken

        case setPayEnabled
        case getBalance
        case getCardDetails(sessionId: String)
        case freeze(cardId: String)
        case unfreeze(cardId: String)
        case getPin(sessionId: String)
        case setPin(pin: String, sessionId: String, iv: String)
        case getTransactionHistory(limit: Int, cursor: String?)

        case getWithdrawSignableData(TangemPayWithdraw.SignableData.Request)
        case sendWithdrawTransaction(TangemPayWithdraw.Transaction.Request)

        case placeOrder(customerWalletAddress: String)
        case getOrder(orderId: String)
    }
}

extension TangemPayCustomerAPITarget: TargetTypeLogConvertible {
    var requestDescription: String {
        path
    }

    var shouldLogResponseBody: Bool {
        false
    }
}
