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

public struct TangemPayTransactionHistoryResponse: Decodable {
    public let transactions: [Transaction]
}

public extension TangemPayTransactionHistoryResponse {
    struct Transaction: Decodable, Equatable {
        public let id: String
        public let record: Record

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            id = try container.decode(String.self, forKey: .id)

            let transactionType = try container.decode(TransactionType.self, forKey: .type)
            switch transactionType {
            case .spend:
                record = .spend(try container.decode(Spend.self, forKey: .spend))
            case .collateral:
                record = .collateral(try container.decode(Collateral.self, forKey: .collateral))
            case .payment:
                record = .payment(try container.decode(Payment.self, forKey: .payment))
            case .fee:
                record = .fee(try container.decode(Fee.self, forKey: .fee))
            }
        }

        enum CodingKeys: CodingKey {
            case id
            case type
            case spend
            case collateral
            case payment
            case fee
        }
    }

    enum Record: Equatable {
        case spend(Spend)
        case collateral(Collateral)
        case payment(Payment)
        case fee(Fee)
    }

    enum TransactionType: String, Decodable, Equatable {
        case spend
        case collateral
        case payment
        case fee
    }

    struct Spend: Decodable, Equatable {
        public let amount: Double
        public let currency: String
        public let localAmount: Double
        public let localCurrency: String
        public let authorizedAmount: Double
        public let memo: String?
        public let receipt: Bool
        public let merchantName: String?
        public let merchantCategory: String?
        public let merchantCategoryCode: String
        public let merchantId: String?
        public let enrichedMerchantIcon: URL?
        public let enrichedMerchantName: String?
        public let enrichedMerchantCategory: String?
        public let cardId: String
        public let cardType: String
        public let status: String
        public let declinedReason: String?
        public let authorizedAt: Date
        public let postedAt: Date?
    }

    struct Collateral: Decodable, Equatable {
        public let amount: Double
        public let currency: String
        public let memo: String
        public let chainId: Double
        public let walletAddress: String
        public let transactionHash: String
        public let postedAt: String
    }

    struct Payment: Decodable, Equatable {
        public let amount: Double
        public let currency: String
        public let memo: String
        public let chainId: Double
        public let walletAddress: String
        public let transactionHash: String
        public let status: String
        public let postedAt: String
    }

    struct Fee: Decodable, Equatable {
        public let amount: Double
        public let currency: String
        public let description: String
        public let postedAt: String
    }
}
