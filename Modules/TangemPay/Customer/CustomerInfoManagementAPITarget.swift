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
    let encoder: JSONEncoder

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
        case .getCardDetails(let cardId, _):
            "customer/card/\(cardId)/details"
        case .freeze:
            "customer/card/freeze"
        case .unfreeze:
            "customer/card/unfreeze"
        case .setPin(let cardId, _, _, _), .getPin(let cardId, _):
            "customer/card/\(cardId)/pin"
        case .getTransactionHistory:
            "customer/transactions"
        case .getWithdrawSignableData:
            "customer/card/withdraw/data"
        case .sendWithdrawTransaction:
            "customer/card/withdraw"
        case .placeOrder, .findOrders:
            "order"
        case .getOrder(let orderId):
            "order/\(orderId)"
        case .getCustomerOffers:
            "customer/offers"
        case .cancelKYC:
            "customer/pay-enabled"
        case .updateCardDisplayName(let cardId, _), .setCardLimit(let cardId, _):
            "customer/card/\(cardId)"
        case .getFee(let type):
            "fees/\(type.rawValue)"
        case .reissueCard:
            "customer/card/reissue"
        }
    }

    var method: Moya.Method {
        switch target {
        case .getCustomerInfo,
             .getKYCAccessToken,
             .getOrder,
             .findOrders,
             .getCustomerOffers,
             .getBalance,
             .getTransactionHistory,
             .getPin,
             .getFee:
            .get

        case .placeOrder,
             .getCardDetails,
             .freeze,
             .unfreeze,
             .getWithdrawSignableData,
             .sendWithdrawTransaction,
             .reissueCard:
            .post

        case .cancelKYC,
             .updateCardDisplayName,
             .setCardLimit:
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
             .getCustomerOffers,
             .getBalance,
             .getPin,
             .getFee:
            return .requestPlain

        case .cancelKYC:
            let requestData = TangemPayCancelKYCRequest()
            return .requestJSONEncodable(requestData)

        case .freeze(let cardId), .unfreeze(let cardId):
            let requestData = TangemPayFreezeUnfreezeRequest(cardId: cardId)
            return .requestJSONEncodable(requestData)

        case .setPin(_, let pin, let sessionId, let iv):
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

        case .findOrders(let orderTypes, let orderStatuses):
            var requestParams: [String: Any] = [:]
            if !orderTypes.isEmpty {
                requestParams["order_types"] = orderTypes
            }
            if !orderStatuses.isEmpty {
                requestParams["order_statuses"] = orderStatuses.map(\.rawValue)
            }
            return .requestParameters(parameters: requestParams, encoding: URLEncoding.default)

        case .getWithdrawSignableData(let request):
            return .requestCustomJSONEncodable(request, encoder: encoder)

        case .sendWithdrawTransaction(let request):
            return .requestCustomJSONEncodable(request, encoder: encoder)

        case .getCardDetails(_, let sessionId):
            let requestData = TangemPayCardDetailsRequest(sessionId: sessionId)
            return .requestJSONEncodable(requestData)

        case .placeOrder(let request, _):
            return .requestCustomJSONEncodable(request, encoder: encoder)

        case .updateCardDisplayName(_, let displayName):
            let requestData = TangemPayUpdateCardDisplayNameRequest(displayName: displayName)
            return .requestCustomJSONEncodable(requestData, encoder: encoder)

        case .reissueCard(let cardId):
            let requestData = TangemPayReissueCardRequest(cardId: cardId)
            return .requestJSONEncodable(requestData)

        case .setCardLimit(_, let amount):
            let requestData = TangemPayUpdateCardLimitRequest(cardLimit: .init(amount: amount))
            return .requestCustomJSONEncodable(requestData, encoder: encoder)
        }
    }

    var headers: [String: String]? {
        switch target {
        case .getPin(_, let sessionId):
            return ["X-Session-Id": "\(sessionId)"]
        case .placeOrder(_, let idempotencyKey):
            return ["Idempotency-Key": idempotencyKey]
        default:
            return nil
        }
    }
}

extension CustomerInfoManagementAPITarget {
    enum Target {
        case getCustomerInfo

        /// Retrieves an access token for the SumSub KYC flow
        case getKYCAccessToken

        case cancelKYC
        case getBalance
        case getCardDetails(cardId: String, sessionId: String)
        case freeze(cardId: String)
        case unfreeze(cardId: String)
        case getPin(cardId: String, sessionId: String)
        case setPin(cardId: String, pin: String, sessionId: String, iv: String)
        case getTransactionHistory(limit: Int, cursor: String?)

        case getWithdrawSignableData(TangemPayWithdraw.SignableData.Request)
        case sendWithdrawTransaction(TangemPayWithdraw.Transaction.Request)

        case placeOrder(TangemPayPlaceOrderRequest, idempotencyKey: String)
        case getOrder(orderId: String)
        case findOrders(orderTypes: [String], orderStatuses: [TangemPayOrderResponse.Status])

        case getCustomerOffers

        case getFee(type: TangemPayFeeType)
        case reissueCard(cardId: String)
        case updateCardDisplayName(cardId: String, displayName: String)
        case setCardLimit(cardId: String, amount: Int)
    }
}

extension CustomerInfoManagementAPITarget: TargetTypeLogConvertible {
    var requestDescription: String {
        path
    }

    var shouldLogResponseBody: Bool {
        false
    }
}
