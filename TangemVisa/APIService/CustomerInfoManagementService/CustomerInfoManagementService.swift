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

public protocol CustomerInfoManagementService {
    func loadCustomerInfo() async throws -> VisaCustomerInfoResponse
    func loadKYCAccessToken() async throws -> VisaKYCAccessTokenResponse

    func getBalance() async throws -> TangemPayBalance
    func getCardDetails(sessionId: String) async throws -> TangemPayCardDetailsResponse
    func freeze(cardId: String) async throws -> TangemPayFreezeUnfreezeResponse
    func unfreeze(cardId: String) async throws -> TangemPayFreezeUnfreezeResponse
    func setPin(pin: String, sessionId: String, iv: String) async throws -> TangemPaySetPinResponse

    func getTransactionHistory(limit: Int, cursor: String?) async throws -> TangemPayTransactionHistoryResponse

    func placeOrder(customerWalletAddress: String) async throws -> TangemPayOrderResponse
    func getOrder(orderId: String) async throws -> TangemPayOrderResponse
}

final class CommonCustomerInfoManagementService {
    typealias CIMAPIService = APIService<CustomerInfoManagementAPITarget>
    private let authorizationTokenHandler: TangemPayAuthorizationTokensHandler
    private let apiService: CIMAPIService

    private let apiType: VisaAPIType

    init(
        apiType: VisaAPIType,
        authorizationTokenHandler: TangemPayAuthorizationTokensHandler,
        apiService: CIMAPIService
    ) {
        self.apiType = apiType
        self.authorizationTokenHandler = authorizationTokenHandler
        self.apiService = apiService
    }

    private func makeRequest(for target: CustomerInfoManagementAPITarget.Target) async throws -> CustomerInfoManagementAPITarget {
        try await authorizationTokenHandler.prepare()

        return .init(
            target: target,
            apiType: apiType
        )
    }
}

extension CommonCustomerInfoManagementService: CustomerInfoManagementService {
    func loadCustomerInfo() async throws -> VisaCustomerInfoResponse {
        return try await apiService.request(
            makeRequest(for: .getCustomerInfo)
        )
    }

    func loadKYCAccessToken() async throws -> VisaKYCAccessTokenResponse {
        try await apiService.request(
            makeRequest(for: .getKYCAccessToken)
        )
    }

    func getBalance() async throws -> TangemPayBalance {
        try await apiService.request(
            makeRequest(for: .getBalance)
        )
    }

    func getCardDetails(sessionId: String) async throws -> TangemPayCardDetailsResponse {
        try await apiService.request(
            makeRequest(for: .getCardDetails(sessionId: sessionId))
        )
    }

    func freeze(cardId: String) async throws -> TangemPayFreezeUnfreezeResponse {
        try await apiService.request(
            makeRequest(for: .freeze(cardId: cardId))
        )
    }

    func unfreeze(cardId: String) async throws -> TangemPayFreezeUnfreezeResponse {
        try await apiService.request(
            makeRequest(for: .unfreeze(cardId: cardId))
        )
    }

    func setPin(pin: String, sessionId: String, iv: String) async throws -> TangemPaySetPinResponse {
        try await apiService.request(
            makeRequest(for: .setPin(pin: pin, sessionId: sessionId, iv: iv))
        )
    }

    func getTransactionHistory(limit: Int, cursor: String?) async throws -> TangemPayTransactionHistoryResponse {
        try await apiService.request(
            makeRequest(for: .getTransactionHistory(limit: limit, cursor: cursor))
        )
    }

    func placeOrder(customerWalletAddress: String) async throws -> TangemPayOrderResponse {
        try await apiService.request(
            makeRequest(for: .placeOrder(customerWalletAddress: customerWalletAddress))
        )
    }

    func getOrder(orderId: String) async throws -> TangemPayOrderResponse {
        try await apiService.request(
            makeRequest(for: .getOrder(orderId: orderId))
        )
    }
}
