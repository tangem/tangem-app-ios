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

    // To be removed in following PRs after breaking changes.
    func getCardDetails(sessionId: String) async throws(TangemPayAPIServiceError) -> TangemPayCardDetailsResponse
    func getPin(sessionId: String) async throws(TangemPayAPIServiceError) -> TangemPayGetPinResponse
    func setPin(pin: String, sessionId: String, iv: String) async throws(TangemPayAPIServiceError) -> TangemPaySetPinResponse
    func placeOrder(customerWalletAddress: String) async throws(TangemPayAPIServiceError) -> TangemPayOrderResponse

    @discardableResult
    func updateCardDisplayName(_ displayName: String) async throws(TangemPayAPIServiceError) -> VisaCustomerInfoResponse.ProductInstance

    @discardableResult
    func setCardLimit(amount: Int) async throws(TangemPayAPIServiceError) -> VisaCustomerInfoResponse.ProductInstance

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

    func getWithdrawPreSignatureInfo(
        request: TangemPayWithdrawRequest
    ) async throws(TangemPayAPIServiceError) -> TangemPayWithdrawPreSignature

    func sendWithdrawTransaction(
        request: TangemPayWithdrawRequest,
        signature: TangemPayWithdrawSignature
    ) async throws(TangemPayAPIServiceError) -> TangemPayWithdrawTransactionResult

    func getOrder(orderId: String) async throws(TangemPayAPIServiceError) -> TangemPayOrderResponse
    func findOrders(
        types: [String],
        statuses: [TangemPayOrderResponse.Status]
    ) async throws(TangemPayAPIServiceError) -> [TangemPayOrderResponse]

    func getCustomerOffers() async throws(TangemPayAPIServiceError) -> TangemPayCustomerOffersResponse

    func getTariffPlanTransitions() async throws(TangemPayAPIServiceError) -> TangemPayTariffPlanTransitionsResponse

    func getFee(type: TangemPayFeeType) async throws(TangemPayAPIServiceError) -> TangemPayFeeResponse
    func reissueCard(cardId: String) async throws(TangemPayAPIServiceError) -> TangemPayReissueCardResponse

    func getBankCredentials(productInstanceId: String) async throws(TangemPayAPIServiceError) -> TangemPayBankCredentialsResponse

    @discardableResult
    func cancelKYC() async throws(TangemPayAPIServiceError) -> TangemPayCancelKYCResponse
}

final class CommonCustomerInfoManagementService {
    private let authorizationTokenHandler: TangemPayAuthorizationTokensHandler
    private let apiService: TangemPayAPIService<CustomerInfoManagementAPITarget>

    private let apiType: VisaAPIType
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()

    init(
        apiType: VisaAPIType,
        authorizationTokenHandler: TangemPayAuthorizationTokensHandler,
        apiService: TangemPayAPIService<CustomerInfoManagementAPITarget>
    ) {
        self.apiType = apiType
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

    public func getCardDetails(sessionId: String) async throws(TangemPayAPIServiceError) -> TangemPayCardDetailsResponse {
        try await request(for: .getCardDetailsLegacy(sessionId: sessionId))
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

    public func setPin(pin: String, sessionId: String, iv: String) async throws(TangemPayAPIServiceError) -> TangemPaySetPinResponse {
        try await request(for: .setPinLegacy(pin: pin, sessionId: sessionId, iv: iv))
    }

    public func closeCard(cardId: String) async throws(TangemPayAPIServiceError) -> TangemPayCloseCardResponse {
        try await request(for: .closeCard(cardId: cardId))
    }

    public func setPin(cardId: String, pin: String, sessionId: String, iv: String) async throws(TangemPayAPIServiceError) -> TangemPaySetPinResponse {
        try await request(for: .setPin(cardId: cardId, pin: pin, sessionId: sessionId, iv: iv))
    }

    public func getPin(sessionId: String) async throws(TangemPayAPIServiceError) -> TangemPayGetPinResponse {
        try await request(for: .getPinLegacy(sessionId: sessionId))
    }

    public func getPin(cardId: String, sessionId: String) async throws(TangemPayAPIServiceError) -> TangemPayGetPinResponse {
        try await request(for: .getPin(cardId: cardId, sessionId: sessionId))
    }

    public func getTransactionHistory(limit: Int, cursor: String?) async throws(TangemPayAPIServiceError) -> TangemPayTransactionHistoryResponse {
        try await request(for: .getTransactionHistory(limit: limit, cursor: cursor))
    }

    public func getWithdrawPreSignatureInfo(request: TangemPayWithdrawRequest) async throws(TangemPayAPIServiceError) -> TangemPayWithdrawPreSignature {
        let request = TangemPayWithdraw.SignableData.Request(
            amountInCents: request.amountInCents,
            recipientAddress: request.destination
        )

        let response: TangemPayWithdraw.SignableData.Response = try await self.request(for: .getWithdrawSignableData(request))

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
        let requestTransaction = TangemPayWithdraw.Transaction.Request(
            amountInCents: request.amountInCents,
            senderAddress: signature.sender,
            recipientAddress: request.destination,
            adminSignature: signature.signature.hexString.addHexPrefix(),
            adminSalt: signature.salt.hexString.addHexPrefix()
        )

        let response: TangemPayWithdraw.Transaction.Response = try await self.request(for: .sendWithdrawTransaction(requestTransaction))
        return TangemPayWithdrawTransactionResult(orderID: response.orderId, host: apiType.baseURL.absoluteString)
    }

    public func updateCardDisplayName(_ displayName: String) async throws(TangemPayAPIServiceError) -> VisaCustomerInfoResponse.ProductInstance {
        try await request(for: .updateCardDisplayNameLegacy(displayName: displayName))
    }

    public func updateCardDisplayName(cardId: String, _ displayName: String) async throws(TangemPayAPIServiceError) -> VisaCustomerInfoResponse.ProductInstance {
        try await request(for: .updateCardDisplayName(cardId: cardId, displayName: displayName))
    }

    public func setCardLimit(amount: Int) async throws(TangemPayAPIServiceError) -> VisaCustomerInfoResponse.ProductInstance {
        try await request(for: .setCardLimitLegacy(amount: amount))
    }

    public func setCardLimit(cardId: String, amount: Int) async throws(TangemPayAPIServiceError) -> VisaCustomerInfoResponse.ProductInstance {
        try await request(for: .setCardLimit(cardId: cardId, amount: amount))
    }

    public func placeOrder(customerWalletAddress: String) async throws(TangemPayAPIServiceError) -> TangemPayOrderResponse {
        try await request(for: .placeOrderLegacy(customerWalletAddress: customerWalletAddress))
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

    public func getFee(type: TangemPayFeeType) async throws(TangemPayAPIServiceError) -> TangemPayFeeResponse {
        try await request(for: .getFee(type: type))
    }

    public func reissueCard(cardId: String) async throws(TangemPayAPIServiceError) -> TangemPayReissueCardResponse {
        try await request(for: .reissueCard(cardId: cardId))
    }

    public func getBankCredentials(productInstanceId: String) async throws(TangemPayAPIServiceError) -> TangemPayBankCredentialsResponse {
        try await request(for: .getBankCredentials(productInstanceId: productInstanceId))
    }
}
