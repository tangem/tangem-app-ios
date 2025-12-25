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

public enum CustomerInfoManagementServiceError: Error {
    case unauthorized
    case otherError(Error)
}

public protocol CustomerInfoManagementService: AnyObject {
    func loadCustomerInfo() async throws(CustomerInfoManagementServiceError) -> VisaCustomerInfoResponse
    func loadKYCAccessToken() async throws -> VisaKYCAccessTokenResponse

    func getBalance() async throws -> TangemPayBalance
    func getCardDetails(sessionId: String) async throws -> TangemPayCardDetailsResponse
    func freeze(cardId: String) async throws -> TangemPayFreezeUnfreezeResponse
    func unfreeze(cardId: String) async throws -> TangemPayFreezeUnfreezeResponse
    func getPin(cardId: String, sessionId: String) async throws -> TangemPayGetPinResponse
    func setPin(pin: String, sessionId: String, iv: String) async throws -> TangemPaySetPinResponse

    func getTransactionHistory(limit: Int, cursor: String?) async throws -> TangemPayTransactionHistoryResponse

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
    func cancelKYC() async throws -> TangemPayCancelKYCResponse
}

final class CommonCustomerInfoManagementService {
    typealias CIMAPIService = APIService<CustomerInfoManagementAPITarget>
    private let authorizationTokenHandler: TangemPayAuthorizationTokensHandler
    private let apiService: CIMAPIService

    private let apiType: VisaAPIType
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()

    init(
        apiType: VisaAPIType,
        authorizationTokenHandler: TangemPayAuthorizationTokensHandler,
        apiService: CIMAPIService
    ) {
        self.apiType = apiType
        self.authorizationTokenHandler = authorizationTokenHandler
        self.apiService = apiService
    }

    private func request<T: Decodable>(for target: CustomerInfoManagementAPITarget.Target) async throws(CustomerInfoManagementServiceError) -> T {
        do {
            try await authorizationTokenHandler.prepare()
        } catch {
            switch error {
            case .unauthorized:
                throw .unauthorized
            case .otherError(let error):
                throw .otherError(error)
            }
        }

        do {
            return try await apiService.request(
                .init(
                    target: target,
                    apiType: apiType,
                    encoder: encoder
                )
            )
        } catch {
            throw .otherError(error)
        }
    }
}

extension CommonCustomerInfoManagementService: CustomerInfoManagementService {
    func cancelKYC() async throws -> TangemPayCancelKYCResponse {
        try await request(for: .setPayEnabled)
    }

    func loadCustomerInfo() async throws(CustomerInfoManagementServiceError) -> VisaCustomerInfoResponse {
        try await request(for: .getCustomerInfo)
    }

    func loadKYCAccessToken() async throws -> VisaKYCAccessTokenResponse {
        try await request(for: .getKYCAccessToken)
    }

    func getBalance() async throws -> TangemPayBalance {
        try await request(for: .getBalance)
    }

    func getCardDetails(sessionId: String) async throws -> TangemPayCardDetailsResponse {
        try await request(for: .getCardDetails(sessionId: sessionId))
    }

    func freeze(cardId: String) async throws -> TangemPayFreezeUnfreezeResponse {
        try await request(for: .freeze(cardId: cardId))
    }

    func unfreeze(cardId: String) async throws -> TangemPayFreezeUnfreezeResponse {
        try await request(for: .unfreeze(cardId: cardId))
    }

    func setPin(pin: String, sessionId: String, iv: String) async throws -> TangemPaySetPinResponse {
        try await request(for: .setPin(pin: pin, sessionId: sessionId, iv: iv))
    }

    func getPin(cardId: String, sessionId: String) async throws -> TangemPayGetPinResponse {
        try await request(for: .getPin(cardId: cardId, sessionId: sessionId))
    }

    func getTransactionHistory(limit: Int, cursor: String?) async throws -> TangemPayTransactionHistoryResponse {
        try await request(for: .getTransactionHistory(limit: limit, cursor: cursor))
    }

    func getWithdrawPreSignatureInfo(request: TangemPayWithdrawRequest) async throws -> TangemPayWithdrawPreSignature {
        let request = TangemPayWithdraw.SignableData.Request(
            amountInCents: request.amountInCents,
            recipientAddress: request.destination
        )

        let response: TangemPayWithdraw.SignableData.Response = try await self.request(for: .getWithdrawSignableData(request))

        return TangemPayWithdrawPreSignature(
            sender: response.senderAddress,
            hash: Data(hex: response.hash),
            salt: Data(hex: response.salt)
        )
    }

    func sendWithdrawTransaction(request: TangemPayWithdrawRequest, signature: TangemPayWithdrawSignature) async throws -> TangemPayWithdrawTransactionResult {
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

    func placeOrder(customerWalletAddress: String) async throws -> TangemPayOrderResponse {
        try await request(for: .placeOrder(customerWalletAddress: customerWalletAddress))
    }

    func getOrder(orderId: String) async throws -> TangemPayOrderResponse {
        try await request(for: .getOrder(orderId: orderId))
    }
}
