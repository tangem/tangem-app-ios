//
//  CustomerInfoManagementAPITarget.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
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
        case .closeCard:
            "customer/card/close"
        case .setPin(let cardId, _, _, _), .getPin(let cardId, _):
            "customer/card/\(cardId)/pin"
        case .getTransactionHistory:
            "transactions"
        case .getTransaction(let transactionId):
            "transactions/\(transactionId)"
        case .getWithdrawSignableData:
            "customer/card/withdraw/data"
        case .sendWithdrawTransaction:
            "customer/card/withdraw"
        case .placeOrder, .findOrders:
            "order"
        case .getOrder(let orderId):
            "order/\(orderId)"
        case .cancelOrder(let orderId):
            "order/\(orderId)/cancel"
        case .sendBankOfframpSignature(let orderId, _, _):
            "order/\(orderId)/bank-offramp/signature"
        case .getCustomerOffers:
            "customer/offers"
        case .getProductInstanceOffers(let productInstanceId):
            "product-instances/\(productInstanceId)/offers"
        case .getBankCredentials(let productInstanceId):
            "account/bank-credentials/\(productInstanceId)"
        case .getBankAccounts:
            "account/bank-accounts"
        case .getBankOfframpOptions:
            "account/bank-offramp/options"
        case .getTariffPlanTransitions:
            "customer/tariff-plan/transitions"
        case .requestTariffPlanPendingTransition:
            "customer/tariff-plan/pending-transition"
        case .cancelTariffPlanPendingTransition:
            "customer/tariff-plan/pending-transition/cancel"
        case .cancelKYC:
            "customer/pay-enabled"
        case .updateCardDisplayName(let cardId, _), .setCardLimit(let cardId, _):
            "customer/card/\(cardId)"
        case .getFee(let type):
            "fees/\(type.rawValue)"
        case .getFees:
            "fees"
        case .reissueCard:
            "customer/card/reissue"
        case .getEligibility:
            "eligibility/channels"
        case .getCashbackSummary:
            "customer/cashback/summary"
        case .getCashbackHistory:
            "customer/cashback/history"
        case .getCashbackPromotions:
            "customer/cashback/promotions"
        case .getCashbackAccrualsDocs:
            "customer/cashback/accruals/docs"
        case .getCashbackTransactionDetails(let transactionId):
            "customer/cashback/\(transactionId)/details"
        }
    }

    var method: Moya.Method {
        switch target {
        case .getCustomerInfo,
             .getKYCAccessToken,
             .getOrder,
             .findOrders,
             .getCustomerOffers,
             .getProductInstanceOffers,
             .getTariffPlanTransitions,
             .getBalance,
             .getTransactionHistory,
             .getTransaction,
             .getPin,
             .getFee,
             .getFees,
             .getCashbackSummary,
             .getCashbackHistory,
             .getCashbackPromotions,
             .getCashbackAccrualsDocs,
             .getCashbackTransactionDetails,
             .getBankCredentials,
             .getBankAccounts,
             .getBankOfframpOptions,
             .getEligibility:
            .get

        case .placeOrder,
             .cancelOrder,
             .sendBankOfframpSignature,
             .getCardDetails,
             .freeze,
             .unfreeze,
             .closeCard,
             .getWithdrawSignableData,
             .sendWithdrawTransaction,
             .reissueCard,
             .requestTariffPlanPendingTransition,
             .cancelTariffPlanPendingTransition:
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
             .cancelOrder,
             .getProductInstanceOffers,
             .getTariffPlanTransitions,
             .cancelTariffPlanPendingTransition,
             .getBalance,
             .getPin,
             .getFee,
             .getBankCredentials,
             .getBankAccounts,
             .getBankOfframpOptions,
             .getTransaction,
             .getCashbackSummary,
             .getCashbackPromotions,
             .getCashbackAccrualsDocs,
             .getCashbackTransactionDetails,
             .getEligibility:
            return .requestPlain

        case .getCustomerOffers(let deeplinkValue):
            guard let deeplinkValue else {
                return .requestPlain
            }
            let requestData = TangemPayCustomerOffersRequest(deeplinkValue: deeplinkValue)
            return .requestParameters(requestData)

        case .getCashbackHistory(let months):
            guard let months else {
                return .requestPlain
            }
            return .requestParameters(parameters: ["months_number": months], encoding: URLEncoding.default)

        case .cancelKYC:
            let requestData = TangemPayCancelKYCRequest()
            return .requestJSONEncodable(requestData)

        case .freeze(let cardId), .unfreeze(let cardId):
            let requestData = TangemPayFreezeUnfreezeRequest(cardId: cardId)
            return .requestJSONEncodable(requestData)

        case .closeCard(let cardId):
            let requestData = TangemPayCloseCardRequest(cardId: cardId)
            return .requestJSONEncodable(requestData)

        case .setPin(_, let pin, let sessionId, let iv):
            let requestData = TangemPaySetPinRequest(pin: pin, sessionId: sessionId, iv: iv)
            return .requestJSONEncodable(requestData)

        case .getFees(let groups):
            let requestParams = ["groups": groups.map(\.rawValue).joined(separator: ",")]
            return .requestParameters(parameters: requestParams, encoding: URLEncoding.default)

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

        case .sendBankOfframpSignature(_, let request, _):
            return .requestCustomJSONEncodable(request, encoder: encoder)

        case .updateCardDisplayName(_, let displayName):
            let requestData = TangemPayUpdateCardDisplayNameRequest(displayName: displayName)
            return .requestCustomJSONEncodable(requestData, encoder: encoder)

        case .reissueCard(let cardId):
            let requestData = TangemPayReissueCardRequest(cardId: cardId)
            return .requestJSONEncodable(requestData)

        case .requestTariffPlanPendingTransition(let pendingTariffPlanId):
            let requestData = TangemPayTariffPlanPendingTransitionRequest(pendingTariffPlanId: pendingTariffPlanId)
            return .requestJSONEncodable(requestData)

        case .setCardLimit(_, let amount):
            let requestData = TangemPayUpdateCardLimitRequest(cardLimit: .init(amount: amount))
            return .requestCustomJSONEncodable(requestData, encoder: encoder)
        }
    }

    var headers: [String: String]? {
        switch target {
        case .getPin(_, let sessionId):
            ["X-Session-Id": "\(sessionId)"]
        case .placeOrder(_, let idempotencyKey), .sendBankOfframpSignature(_, _, let idempotencyKey):
            ["Idempotency-Key": idempotencyKey]
        case .getCustomerInfo,
             .getTariffPlanTransitions,
             .getCustomerOffers,
             .getProductInstanceOffers,
             .getCashbackPromotions,
             .getCashbackAccrualsDocs:
            [TangemPayNetworkingConstants.Header.Key.acceptLanguage: Locale.appLanguageCode]
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
        case getTransaction(transactionId: String)

        case getWithdrawSignableData(TangemPayWithdraw.SignableData.Request)
        case sendWithdrawTransaction(TangemPayWithdraw.Transaction.Request)

        case getOrder(orderId: String)
        case cancelOrder(orderId: String)
        case sendBankOfframpSignature(orderId: String, request: TangemPayOfframpSignatureRequest, idempotencyKey: String)
        case findOrders(orderTypes: [String], orderStatuses: [TangemPayOrderResponse.Status])

        case getCustomerOffers(deeplinkValue: String?)
        case getProductInstanceOffers(productInstanceId: String)

        case getTariffPlanTransitions
        case requestTariffPlanPendingTransition(pendingTariffPlanId: String)
        case cancelTariffPlanPendingTransition

        case getFee(type: TangemPayFeeType)
        case getFees(groups: [TangemPayFeeGroup])
        case reissueCard(cardId: String)

        case getBankCredentials(productInstanceId: String)
        case getBankAccounts
        case getBankOfframpOptions

        case getEligibility
        case getCashbackSummary
        case getCashbackHistory(months: Int?)
        case getCashbackPromotions
        case getCashbackAccrualsDocs
        case getCashbackTransactionDetails(transactionId: String)
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
