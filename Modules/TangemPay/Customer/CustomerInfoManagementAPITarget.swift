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
        case .getCardDetailsLegacy:
            "customer/card/details"
        case .getCardDetails(let cardId, _):
            "customer/card/\(cardId)/details"
        case .freeze:
            "customer/card/freeze"
        case .unfreeze:
            "customer/card/unfreeze"
        case .getPinLegacy, .setPinLegacy:
            "customer/card/pin"
        case .closeCard:
            "customer/card/close"
        case .setPin(let cardId, _, _, _), .getPin(let cardId, _):
            "customer/card/\(cardId)/pin"
        case .getTransactionHistory:
            "customer/transactions"
        case .getWithdrawSignableData:
            "customer/card/withdraw/data"
        case .sendWithdrawTransaction:
            "customer/card/withdraw"
        case .placeOrderLegacy, .placeOrder, .findOrders:
            "order"
        case .getOrder(let orderId):
            "order/\(orderId)"
        case .getCustomerOffers:
            "customer/offers"
        case .getBankCredentials(let productInstanceId):
            "account/bank-credentials/\(productInstanceId)"
        case .getTariffPlanTransitions:
            "customer/tariff-plan/transitions"
        case .cancelKYC:
            "customer/pay-enabled"
        case .updateCardDisplayNameLegacy, .setCardLimitLegacy:
            "customer/card"
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
             .getTariffPlanTransitions,
             .getBalance,
             .getTransactionHistory,
             .getPinLegacy,
             .getPin,
             .getFee,
             .getBankCredentials:
            .get

        case .placeOrderLegacy,
             .placeOrder,
             .getCardDetailsLegacy,
             .getCardDetails,
             .freeze,
             .unfreeze,
             .closeCard,
             .getWithdrawSignableData,
             .sendWithdrawTransaction,
             .reissueCard:
            .post

        case .cancelKYC,
             .updateCardDisplayNameLegacy,
             .updateCardDisplayName,
             .setCardLimitLegacy,
             .setCardLimit:
            .patch

        case .setPinLegacy, .setPin:
            .put
        }
    }

    var task: Moya.Task {
        switch target {
        case .getCustomerInfo,
             .getKYCAccessToken,
             .getOrder,
             .getCustomerOffers,
             .getTariffPlanTransitions,
             .getBalance,
             .getPinLegacy,
             .getPin,
             .getFee,
             .getBankCredentials:
            return .requestPlain

        case .cancelKYC:
            let requestData = TangemPayCancelKYCRequest()
            return .requestJSONEncodable(requestData)

        case .freeze(let cardId), .unfreeze(let cardId):
            let requestData = TangemPayFreezeUnfreezeRequest(cardId: cardId)
            return .requestJSONEncodable(requestData)

        case .setPinLegacy(let pin, let sessionId, let iv):
            let requestData = TangemPaySetPinRequest(pin: pin, sessionId: sessionId, iv: iv)
            return .requestJSONEncodable(requestData)

        case .closeCard(let cardId):
            let requestData = TangemPayCloseCardRequest(cardId: cardId)
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

        case .getCardDetailsLegacy(let sessionId):
            let requestData = TangemPayCardDetailsRequest(sessionId: sessionId)
            return .requestJSONEncodable(requestData)

        case .getCardDetails(_, let sessionId):
            let requestData = TangemPayCardDetailsRequest(sessionId: sessionId)
            return .requestJSONEncodable(requestData)

        case .placeOrderLegacy(let customerWalletAddress):
            let requestData = TangemPayPlaceOrderRequest(customerWalletAddress: customerWalletAddress)
            return .requestJSONEncodable(requestData)

        case .placeOrder(let request, _):
            return .requestCustomJSONEncodable(request, encoder: encoder)

        case .updateCardDisplayNameLegacy(let displayName):
            let requestData = TangemPayUpdateCardDisplayNameRequest(displayName: displayName)
            return .requestCustomJSONEncodable(requestData, encoder: encoder)

        case .updateCardDisplayName(_, let displayName):
            let requestData = TangemPayUpdateCardDisplayNameRequest(displayName: displayName)
            return .requestCustomJSONEncodable(requestData, encoder: encoder)

        case .reissueCard(let cardId):
            let requestData = TangemPayReissueCardRequest(cardId: cardId)
            return .requestJSONEncodable(requestData)

        case .setCardLimitLegacy(let amount):
            let requestData = TangemPayUpdateCardLimitRequest(cardLimit: .init(amount: amount))
            return .requestCustomJSONEncodable(requestData, encoder: encoder)

        case .setCardLimit(_, let amount):
            let requestData = TangemPayUpdateCardLimitRequest(cardLimit: .init(amount: amount))
            return .requestCustomJSONEncodable(requestData, encoder: encoder)
        }
    }

    var headers: [String: String]? {
        switch target {
        case .getPinLegacy(let sessionId):
            ["X-Session-Id": "\(sessionId)"]
        case .getPin(_, let sessionId):
            ["X-Session-Id": "\(sessionId)"]
        case .placeOrder(_, let idempotencyKey):
            ["Idempotency-Key": idempotencyKey]
        default:
            nil
        }
    }
}

extension CustomerInfoManagementAPITarget {
    enum Target {
        /// Load all available customer info. Can be used for loading data about payment account address
        /// Will be updated later, not fully implemented on BFF
        case getCustomerInfo

        /// Retrieves an access token for the SumSub KYC flow
        case getKYCAccessToken

        case cancelKYC
        case getBalance

        // To be removed in following PRs after breaking changes.
        case getCardDetailsLegacy(sessionId: String)
        case getPinLegacy(sessionId: String)
        case setPinLegacy(pin: String, sessionId: String, iv: String)
        case placeOrderLegacy(customerWalletAddress: String)
        case updateCardDisplayNameLegacy(displayName: String)
        case setCardLimitLegacy(amount: Int)

        case getCardDetails(cardId: String, sessionId: String)
        case closeCard(cardId: String)
        case getPin(cardId: String, sessionId: String)
        case setPin(cardId: String, pin: String, sessionId: String, iv: String)
        case placeOrder(TangemPayPlaceOrderRequest, idempotencyKey: String)
        case updateCardDisplayName(cardId: String, displayName: String)
        case setCardLimit(cardId: String, amount: Int)

        case freeze(cardId: String)
        case unfreeze(cardId: String)
        case getTransactionHistory(limit: Int, cursor: String?)

        case getWithdrawSignableData(TangemPayWithdraw.SignableData.Request)
        case sendWithdrawTransaction(TangemPayWithdraw.Transaction.Request)

        case getOrder(orderId: String)
        case findOrders(orderTypes: [String], orderStatuses: [TangemPayOrderResponse.Status])

        case getCustomerOffers

        case getTariffPlanTransitions

        case getFee(type: TangemPayFeeType)
        case reissueCard(cardId: String)

        case getBankCredentials(productInstanceId: String)
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
