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

actor CommonCustomerInfoManagementService {
    typealias CIMAPIService = APIService<CustomerInfoManagementAPITarget>
    private let authorizationTokenHandler: TangemPayAuthorizationTokensHandler
    private let apiService: CIMAPIService

    private let apiType: VisaAPIType
    private let authorizeWithCustomerWallet: () async throws -> TangemPayAuthorizationTokens

    private var tokenPreparingTask: _Concurrency.Task<Void, Error>?

    init(
        apiType: VisaAPIType,
        authorizationTokenHandler: TangemPayAuthorizationTokensHandler,
        apiService: CIMAPIService,
        authorizeWithCustomerWallet: @escaping () async throws -> TangemPayAuthorizationTokens
    ) {
        self.apiType = apiType
        self.authorizationTokenHandler = authorizationTokenHandler
        self.apiService = apiService
        self.authorizeWithCustomerWallet = authorizeWithCustomerWallet
    }

    private func makeRequest(for target: CustomerInfoManagementAPITarget.Target) async throws -> CustomerInfoManagementAPITarget {
        try await prepareTokensHandler()

        return .init(
            target: target,
            apiType: apiType
        )
    }

    private func prepareTokensHandler() async throws {
        if let tokenPreparingTask {
            return try await tokenPreparingTask.value
        }

        defer {
            tokenPreparingTask = nil
        }

        tokenPreparingTask = runTask(in: self) { service in
            try await service.refreshTokenIfNeeded()
        }

        try await tokenPreparingTask?.value
    }

    private func refreshTokenIfNeeded() async throws {
        if authorizationTokenHandler.refreshTokenExpired {
            let tokens = try await authorizeWithCustomerWallet()
            try await authorizationTokenHandler.setupTokens(tokens)
        }

        if authorizationTokenHandler.accessTokenExpired {
            do {
                try await authorizationTokenHandler.forceRefreshToken()

                // Either:
                // 1. Maximum allowed refresh token reuse exceeded
                // 2. Session doesn't have required client
            } catch where error.universalErrorCode == 104110202 {
                // Call of `forceRefreshToken` func could fail if same refresh becomes invalid (not expired, but invalid)
                // That could happen if:
                // 1. Token refresh called twice on the same device (could happen in there is a race condition somewhere)
                // 2. User have one TangemPay account linked to more than one device
                // (i.e. calling token refresh on one device automatically makes refresh token on second device invalid)
                let tokens = try await authorizeWithCustomerWallet()
                try await authorizationTokenHandler.setupTokens(tokens)
            }
        }
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
