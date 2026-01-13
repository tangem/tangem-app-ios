//
//  TangemPayCustomerService.swift
//  TangemPay
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import Moya
import TangemFoundation

public protocol TangemPayCustomerService: AnyObject {
    func loadCustomerInfo() async throws(TangemPayAPIServiceError) -> TangemPayCustomer
    func loadKYCAccessToken() async throws(TangemPayAPIServiceError) -> TangemPayKYCAccessTokenResponse

    func getBalance() async throws(TangemPayAPIServiceError) -> TangemPayBalance
    func getCardDetails(sessionId: String) async throws(TangemPayAPIServiceError) -> TangemPayCardDetailsResponse
    func freeze(cardId: String) async throws(TangemPayAPIServiceError) -> TangemPayFreezeUnfreezeResponse
    func unfreeze(cardId: String) async throws(TangemPayAPIServiceError) -> TangemPayFreezeUnfreezeResponse
    func getPin(sessionId: String) async throws(TangemPayAPIServiceError) -> TangemPayGetPinResponse
    func setPin(pin: String, sessionId: String, iv: String) async throws(TangemPayAPIServiceError) -> TangemPaySetPinResponse

    func getTransactionHistory(limit: Int, cursor: String?) async throws(TangemPayAPIServiceError) -> TangemPayTransactionHistoryResponse

    func getWithdrawPreSignatureInfo(
        request: TangemPayWithdrawRequest
    ) async throws -> TangemPayWithdrawPreSignature

    func sendWithdrawTransaction(
        request: TangemPayWithdrawRequest,
        signature: TangemPayWithdrawSignature
    ) async throws -> TangemPayWithdrawTransactionResult

    func placeOrder(customerWalletAddress: String) async throws -> TangemPayOrderResponse
    func getOrder(orderId: String) async throws -> TangemPayOrderResponse

    @discardableResult
    func cancelKYC() async throws -> TangemPaySetPayEnabledResponse
}

final class CommonTangemPayCustomerService {
    private let authorizationTokenHandler: TangemPayAuthorizationTokensHandler
    private let apiService: TangemPayAPIService<TangemPayCustomerAPITarget>

    private let apiType: TangemPayAPIType
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()

    init(
        apiType: TangemPayAPIType,
        authorizationTokenHandler: TangemPayAuthorizationTokensHandler,
        apiService: TangemPayAPIService<TangemPayCustomerAPITarget>
    ) {
        self.apiType = apiType
        self.authorizationTokenHandler = authorizationTokenHandler
        self.apiService = apiService
    }

    private func request<T: Decodable>(for target: TangemPayCustomerAPITarget.Target) async throws(TangemPayAPIServiceError) -> T {
        try await authorizationTokenHandler.prepare()

        return try await apiService.request(
            .init(
                target: target,
                apiType: apiType,
                encoder: encoder
            ),
            format: .wrapped
        )
    }
}

extension CommonTangemPayCustomerService: TangemPayCustomerService {
    public func cancelKYC() async throws(TangemPayAPIServiceError) -> TangemPaySetPayEnabledResponse {
        try await request(for: .setPayEnabled)
    }

    public func loadCustomerInfo() async throws(TangemPayAPIServiceError) -> TangemPayCustomer {
        try await request(for: .getCustomerInfo)
    }

    public func loadKYCAccessToken() async throws(TangemPayAPIServiceError) -> TangemPayKYCAccessTokenResponse {
        try await request(for: .getKYCAccessToken)
    }

    public func getBalance() async throws(TangemPayAPIServiceError) -> TangemPayBalance {
        try await request(for: .getBalance)
    }

    public func getCardDetails(sessionId: String) async throws(TangemPayAPIServiceError) -> TangemPayCardDetailsResponse {
        try await request(for: .getCardDetails(sessionId: sessionId))
    }

    public func freeze(cardId: String) async throws(TangemPayAPIServiceError) -> TangemPayFreezeUnfreezeResponse {
        try await request(for: .freeze(cardId: cardId))
    }

    public func unfreeze(cardId: String) async throws(TangemPayAPIServiceError) -> TangemPayFreezeUnfreezeResponse {
        try await request(for: .unfreeze(cardId: cardId))
    }

    public func setPin(pin: String, sessionId: String, iv: String) async throws(TangemPayAPIServiceError) -> TangemPaySetPinResponse {
        try await request(for: .setPin(pin: pin, sessionId: sessionId, iv: iv))
    }

    public func getPin(sessionId: String) async throws(TangemPayAPIServiceError) -> TangemPayGetPinResponse {
        try await request(for: .getPin(sessionId: sessionId))
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
            salt: Data(hexString: response.salt)
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

    public func placeOrder(customerWalletAddress: String) async throws(TangemPayAPIServiceError) -> TangemPayOrderResponse {
        try await request(for: .placeOrder(customerWalletAddress: customerWalletAddress))
    }

    public func getOrder(orderId: String) async throws(TangemPayAPIServiceError) -> TangemPayOrderResponse {
        try await request(for: .getOrder(orderId: orderId))
    }
}
