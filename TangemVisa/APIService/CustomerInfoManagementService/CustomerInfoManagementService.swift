//
//  CustomerInfoManagementService.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya

public protocol CustomerInfoManagementService {
    func loadCustomerInfo() async throws -> VisaCustomerInfoResponse
    func loadKYCAccessToken() async throws -> VisaKYCAccessTokenResponse

    func getBalance() async throws -> TangemPayBalance
    func getCardDetails(sessionId: String) async throws -> TangemPayCardDetailsResponse
    func getTransactionHistory(limit: Int, cursor: String?) async throws -> TangemPayTransactionHistoryResponse

    func placeOrder(walletAddress: String) async throws -> TangemPayOrderResponse
    func getOrder(orderId: String) async throws -> TangemPayOrderResponse
}

/// For backwards compatibility.
/// Will be removed in [REDACTED_INFO]
public extension CustomerInfoManagementService {
    func loadCustomerInfo(cardId: String) async throws -> VisaCustomerInfoResponse {
        try await loadCustomerInfo()
    }
}

class CommonCustomerInfoManagementService {
    typealias CIMAPIService = APIService<CustomerInfoManagementAPITarget>
    private let authorizationTokenHandler: VisaAuthorizationTokensHandler
    private let apiService: CIMAPIService

    private let apiType: VisaAPIType

    init(
        apiType: VisaAPIType,
        authorizationTokenHandler: VisaAuthorizationTokensHandler,
        apiService: CIMAPIService
    ) {
        self.apiType = apiType
        self.authorizationTokenHandler = authorizationTokenHandler
        self.apiService = apiService
    }

    private func makeRequest(for target: CustomerInfoManagementAPITarget.Target) async throws -> CustomerInfoManagementAPITarget {
        let authorizationToken = try await authorizationTokenHandler.authorizationHeader

        return .init(
            authorizationToken: authorizationToken,
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

    func getTransactionHistory(limit: Int, cursor: String?) async throws -> TangemPayTransactionHistoryResponse {
        try await apiService.request(
            makeRequest(for: .getTransactionHistory(limit: limit, cursor: cursor))
        )
    }

    func placeOrder(walletAddress: String) async throws -> TangemPayOrderResponse {
        try await apiService.request(
            makeRequest(for: .placeOrder(walletAddress: walletAddress))
        )
    }

    func getOrder(orderId: String) async throws -> TangemPayOrderResponse {
        try await apiService.request(
            makeRequest(for: .getOrder(orderId: orderId))
        )
    }
}
