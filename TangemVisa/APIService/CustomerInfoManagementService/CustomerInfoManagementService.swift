//
//  CustomerInfoManagementService.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya

public struct TangemPayCardDetailsResponse: Decodable {
    public struct Secret: Decodable {
        public let secret: String
        public let iv: String
    }

    public let expirationMonth: String
    public let expirationYear: String
    public let pan: Secret
    public let cvv: Secret
}

public protocol CustomerInfoManagementService {
    func loadCustomerInfo() async throws -> VisaCustomerInfoResponse
    func loadKYCAccessToken() async throws -> VisaKYCAccessTokenResponse

    func placeOrder(walletAddress: String) async throws -> TangemPayOrderResponse
    func getOrder(orderId: String) async throws -> TangemPayOrderResponse

    func getCardDetails(sessionId: String) async throws -> TangemPayCardDetailsResponse
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

    func getCardDetails(sessionId: String) async throws -> TangemPayCardDetailsResponse {
        try await apiService.request(
            makeRequest(for: .getCardDetails(sessionId: sessionId))
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
