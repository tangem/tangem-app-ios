//
//  CustomerInfoManagementService.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemFoundation

public protocol CustomerInfoManagementService: AnyObject {
    func loadCustomerInfo() async throws(TangemPayAPIServiceError) -> VisaCustomerInfoResponse
    func loadKYCAccessToken() async throws(TangemPayAPIServiceError) -> VisaKYCAccessTokenResponse

    func getBalance() async throws(TangemPayAPIServiceError) -> TangemPayBalance

    func getCardDetails(cardId: String, sessionId: String) async throws(TangemPayAPIServiceError) -> TangemPayCardDetailsResponse
    func closeCard(cardId: String) async throws(TangemPayAPIServiceError) -> TangemPayCloseCardResponse
    func getPin(cardId: String, sessionId: String) async throws(TangemPayAPIServiceError) -> TangemPayGetPinResponse
    func setPin(cardId: String, pin: String, sessionId: String, iv: String) async throws(TangemPayAPIServiceError) -> TangemPaySetPinResponse
    func placeOrder(
        request: TangemPayPlaceOrderRequest,
        idempotencyKey: String
    ) async throws(TangemPayAPIServiceError) -> TangemPayOrderResponse

    @discardableResult
    func updateCardDisplayName(cardId: String, _ displayName: String) async throws(TangemPayAPIServiceError) -> VisaCustomerInfoResponse.ProductInstance

    @discardableResult
    func setCardLimit(cardId: String, amount: Int) async throws(TangemPayAPIServiceError) -> VisaCustomerInfoResponse.ProductInstance

    func freeze(cardId: String) async throws(TangemPayAPIServiceError) -> TangemPayFreezeUnfreezeResponse
    func unfreeze(cardId: String) async throws(TangemPayAPIServiceError) -> TangemPayFreezeUnfreezeResponse

    func getTransactionHistory(limit: Int, cursor: String?) async throws(TangemPayAPIServiceError) -> TangemPayTransactionHistoryResponse

    func getTransaction(transactionId: String) async throws(TangemPayAPIServiceError) -> TangemPayTransactionHistoryResponse.Transaction

    func getWithdrawPreSignatureInfo(
        request: TangemPayWithdrawRequest
    ) async throws(TangemPayAPIServiceError) -> TangemPayWithdrawPreSignature

    func sendWithdrawTransaction(
        request: TangemPayWithdrawRequest,
        signature: TangemPayWithdrawSignature
    ) async throws(TangemPayAPIServiceError) -> TangemPayWithdrawTransactionResult

    func getOrder(orderId: String) async throws(TangemPayAPIServiceError) -> TangemPayOrderResponse

    @discardableResult
    func cancelOrder(orderId: String) async throws(TangemPayAPIServiceError) -> TangemPayCancelOrderResponse

    func findOrders(
        types: [String],
        statuses: [TangemPayOrderResponse.Status]
    ) async throws(TangemPayAPIServiceError) -> [TangemPayOrderResponse]

    func getCustomerOffers() async throws(TangemPayAPIServiceError) -> TangemPayCustomerOffersResponse

    func getTariffPlanTransitions() async throws(TangemPayAPIServiceError) -> TangemPayTariffPlanTransitionsResponse

    @discardableResult
    func requestTariffPlanPendingTransition(
        pendingTariffPlanId: String
    ) async throws(TangemPayAPIServiceError) -> VisaCustomerInfoResponse.CustomerTariffPlan

    @discardableResult
    func cancelTariffPlanPendingTransition() async throws(TangemPayAPIServiceError) -> VisaCustomerInfoResponse.CustomerTariffPlan

    func getFee(type: TangemPayFeeType) async throws(TangemPayAPIServiceError) -> TangemPayFeeResponse
    func getFees(groups: [TangemPayFeeGroup]) async throws(TangemPayAPIServiceError) -> [TangemPayFeeResponse]
    func reissueCard(cardId: String) async throws(TangemPayAPIServiceError) -> TangemPayReissueCardResponse

    func getBankCredentials(productInstanceId: String) async throws(TangemPayAPIServiceError) -> TangemPayBankCredentialsResponse
    func loadEligibility() async throws(TangemPayAPIServiceError) -> TangemPayAvailabilityResponse

    func getCashbackSummary() async throws(TangemPayAPIServiceError) -> TangemPayCashbackSummaryResponse
    func getCashbackHistory(months: Int?) async throws(TangemPayAPIServiceError) -> TangemPayCashbackHistoryResponse
    func getCashbackPromotions() async throws(TangemPayAPIServiceError) -> TangemPayCashbackPromotionsResponse
    func getCashbackAccrualsDocs() async throws(TangemPayAPIServiceError) -> TangemPayCashbackAccrualsDocsResponse

    func getCashbackTransactionDetails(
        transactionId: String
    ) async throws(TangemPayAPIServiceError) -> TangemPayCashbackTransactionDetailsResponse

    @discardableResult
    func cancelKYC() async throws(TangemPayAPIServiceError) -> TangemPayCancelKYCResponse
}

final class CommonCustomerInfoManagementService {
    private let authorizationTokenHandler: TangemPayAuthorizationTokensHandler
    private let apiService: TangemPayAPIService<CustomerInfoManagementAPITarget>

    private let apiType: VisaAPIType
    private let useNewTransactionsEndpoint: Bool
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()

    init(
        apiType: VisaAPIType,
        useNewTransactionsEndpoint: Bool,
        authorizationTokenHandler: TangemPayAuthorizationTokensHandler,
        apiService: TangemPayAPIService<CustomerInfoManagementAPITarget>
    ) {
        self.apiType = apiType
        self.useNewTransactionsEndpoint = useNewTransactionsEndpoint
        self.authorizationTokenHandler = authorizationTokenHandler
        self.apiService = apiService
    }

    private func request<T: Decodable>(for target: CustomerInfoManagementAPITarget.Target) async throws(TangemPayAPIServiceError) -> T {
        try await authorizationTokenHandler.prepare()

        return try await apiService.request(
            .init(
                target: target,
                apiType: apiType,
                encoder: encoder
            )
        )
    }
}

extension CommonCustomerInfoManagementService: CustomerInfoManagementService {
    public func cancelKYC() async throws(TangemPayAPIServiceError) -> TangemPayCancelKYCResponse {
        try await request(for: .cancelKYC)
    }

    public func loadCustomerInfo() async throws(TangemPayAPIServiceError) -> VisaCustomerInfoResponse {
        try await request(for: .getCustomerInfo)
    }

    public func loadKYCAccessToken() async throws(TangemPayAPIServiceError) -> VisaKYCAccessTokenResponse {
        try await request(for: .getKYCAccessToken)
    }

    public func getBalance() async throws(TangemPayAPIServiceError) -> TangemPayBalance {
        try await request(for: .getBalance)
    }

    public func getCardDetails(cardId: String, sessionId: String) async throws(TangemPayAPIServiceError) -> TangemPayCardDetailsResponse {
        try await request(for: .getCardDetails(cardId: cardId, sessionId: sessionId))
    }

    public func freeze(cardId: String) async throws(TangemPayAPIServiceError) -> TangemPayFreezeUnfreezeResponse {
        try await request(for: .freeze(cardId: cardId))
    }

    public func unfreeze(cardId: String) async throws(TangemPayAPIServiceError) -> TangemPayFreezeUnfreezeResponse {
        try await request(for: .unfreeze(cardId: cardId))
    }

    public func closeCard(cardId: String) async throws(TangemPayAPIServiceError) -> TangemPayCloseCardResponse {
        try await request(for: .closeCard(cardId: cardId))
    }

    public func setPin(cardId: String, pin: String, sessionId: String, iv: String) async throws(TangemPayAPIServiceError) -> TangemPaySetPinResponse {
        try await request(for: .setPin(cardId: cardId, pin: pin, sessionId: sessionId, iv: iv))
    }

    public func getPin(cardId: String, sessionId: String) async throws(TangemPayAPIServiceError) -> TangemPayGetPinResponse {
        try await request(for: .getPin(cardId: cardId, sessionId: sessionId))
    }

    public func getTransactionHistory(limit: Int, cursor: String?) async throws(TangemPayAPIServiceError) -> TangemPayTransactionHistoryResponse {
        try await request(
            for: useNewTransactionsEndpoint
                ? .getTransactionHistory(limit: limit, cursor: cursor)
                : .getTransactionHistoryLegacy(limit: limit, cursor: cursor)
        )
    }

    public func getTransaction(transactionId: String) async throws(TangemPayAPIServiceError) -> TangemPayTransactionHistoryResponse.Transaction {
        try await request(
            for: useNewTransactionsEndpoint
                ? .getTransaction(transactionId: transactionId)
                : .getTransactionLegacy(transactionId: transactionId)
        )
    }

    public func getWithdrawPreSignatureInfo(request: TangemPayWithdrawRequest) async throws(TangemPayAPIServiceError) -> TangemPayWithdrawPreSignature {
        let signableDataRequest = TangemPayWithdraw.SignableData.Request(request)

        let response: TangemPayWithdraw.SignableData.Response = try await self.request(for: .getWithdrawSignableData(signableDataRequest))

        return TangemPayWithdrawPreSignature(
            sender: response.senderAddress,
            hash: Data(hexString: response.hash),
            salt: Data(hexString: response.salt),
            structuredData: response.structuredData
        )
    }

    public func sendWithdrawTransaction(
        request: TangemPayWithdrawRequest,
        signature: TangemPayWithdrawSignature
    ) async throws(TangemPayAPIServiceError) -> TangemPayWithdrawTransactionResult {
        let requestTransaction = TangemPayWithdraw.Transaction.Request(request, signature: signature)

        let response: TangemPayWithdraw.Transaction.Response = try await self.request(for: .sendWithdrawTransaction(requestTransaction))
        return TangemPayWithdrawTransactionResult(orderID: response.orderId, host: apiType.baseURL.absoluteString)
    }

    public func updateCardDisplayName(cardId: String, _ displayName: String) async throws(TangemPayAPIServiceError) -> VisaCustomerInfoResponse.ProductInstance {
        try await request(for: .updateCardDisplayName(cardId: cardId, displayName: displayName))
    }

    public func setCardLimit(cardId: String, amount: Int) async throws(TangemPayAPIServiceError) -> VisaCustomerInfoResponse.ProductInstance {
        try await request(for: .setCardLimit(cardId: cardId, amount: amount))
    }

    public func placeOrder(
        request: TangemPayPlaceOrderRequest,
        idempotencyKey: String
    ) async throws(TangemPayAPIServiceError) -> TangemPayOrderResponse {
        try await self.request(for: .placeOrder(request, idempotencyKey: idempotencyKey))
    }

    public func getOrder(orderId: String) async throws(TangemPayAPIServiceError) -> TangemPayOrderResponse {
        try await request(for: .getOrder(orderId: orderId))
    }

    public func cancelOrder(orderId: String) async throws(TangemPayAPIServiceError) -> TangemPayCancelOrderResponse {
        try await request(for: .cancelOrder(orderId: orderId))
    }

    public func findOrders(
        types: [String],
        statuses: [TangemPayOrderResponse.Status]
    ) async throws(TangemPayAPIServiceError) -> [TangemPayOrderResponse] {
        try await request(for: .findOrders(orderTypes: types, orderStatuses: statuses))
    }

    public func getCustomerOffers() async throws(TangemPayAPIServiceError) -> TangemPayCustomerOffersResponse {
        try await request(for: .getCustomerOffers)
    }

    public func getTariffPlanTransitions() async throws(TangemPayAPIServiceError) -> TangemPayTariffPlanTransitionsResponse {
        try await request(for: .getTariffPlanTransitions)
    }

    @discardableResult
    public func requestTariffPlanPendingTransition(
        pendingTariffPlanId: String
    ) async throws(TangemPayAPIServiceError) -> VisaCustomerInfoResponse.CustomerTariffPlan {
        try await request(for: .requestTariffPlanPendingTransition(pendingTariffPlanId: pendingTariffPlanId))
    }

    @discardableResult
    public func cancelTariffPlanPendingTransition() async throws(TangemPayAPIServiceError) -> VisaCustomerInfoResponse.CustomerTariffPlan {
        try await request(for: .cancelTariffPlanPendingTransition)
    }

    public func getFee(type: TangemPayFeeType) async throws(TangemPayAPIServiceError) -> TangemPayFeeResponse {
        try await request(for: .getFee(type: type))
    }

    public func getFees(groups: [TangemPayFeeGroup]) async throws(TangemPayAPIServiceError) -> [TangemPayFeeResponse] {
        try await request(for: .getFees(groups: groups))
    }

    public func reissueCard(cardId: String) async throws(TangemPayAPIServiceError) -> TangemPayReissueCardResponse {
        try await request(for: .reissueCard(cardId: cardId))
    }

    public func getBankCredentials(productInstanceId: String) async throws(TangemPayAPIServiceError) -> TangemPayBankCredentialsResponse {
        try await request(for: .getBankCredentials(productInstanceId: productInstanceId))
    }

    public func loadEligibility() async throws(TangemPayAPIServiceError) -> TangemPayAvailabilityResponse {
        try await request(for: .getEligibility)
    }

    public func getCashbackSummary() async throws(TangemPayAPIServiceError) -> TangemPayCashbackSummaryResponse {
        try await request(for: .getCashbackSummary)
    }

    public func getCashbackHistory(months: Int?) async throws(TangemPayAPIServiceError) -> TangemPayCashbackHistoryResponse {
        try await request(for: .getCashbackHistory(months: months))
    }

    public func getCashbackPromotions() async throws(TangemPayAPIServiceError) -> TangemPayCashbackPromotionsResponse {
        try await request(for: .getCashbackPromotions)
    }

    public func getCashbackAccrualsDocs() async throws(TangemPayAPIServiceError) -> TangemPayCashbackAccrualsDocsResponse {
        try await request(for: .getCashbackAccrualsDocs)
    }

    public func getCashbackTransactionDetails(
        transactionId: String
    ) async throws(TangemPayAPIServiceError) -> TangemPayCashbackTransactionDetailsResponse {
        try await request(for: .getCashbackTransactionDetails(transactionId: transactionId))
    }
}
