//
//  GaslessTransactionsAPIService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemNetworkUtils

protocol GaslessTransactionsAPIService {
    typealias FeeToken = GaslessTransactionsDTO.Response.FeeToken
    typealias MetaTransaction = GaslessTransactionsDTO.Request.GaslessTransaction
    typealias SignResult = GaslessTransactionsDTO.Response.SignResponse.Result

    func getAvailableTokens() async throws -> [FeeToken]
    func signGaslessTransaction(_ transaction: GaslessTransactionsDTO.Request.GaslessTransaction) async throws -> SignResult
}

final class CommonGaslessTransactionAPIService {
    private let provider: TangemProvider<GaslessTransactionsAPITarget>
    private let apiType: GaslessTransactionsAPIType

    init(provider: TangemProvider<GaslessTransactionsAPITarget>, apiType: GaslessTransactionsAPIType) {
        self.provider = provider
        self.apiType = apiType
    }
}

extension CommonGaslessTransactionAPIService: GaslessTransactionsAPIService {
    func getAvailableTokens() async throws -> [FeeToken] {
        let response: GaslessTransactionsDTO.Response.GaslessFeeTokensResult = try await request(for: .availableTokens)
        return response.tokens
    }

    func signGaslessTransaction(_ transaction: MetaTransaction) async throws -> SignResult {
        let response: GaslessTransactionsDTO.Response.SignResponse = try await request(for: .signGaslessTransaction(transaction: transaction))
        return response.result
    }
}

private extension CommonGaslessTransactionAPIService {
    func request<T: Decodable>(for target: GaslessTransactionsAPITarget.TargetType) async throws -> T {
        let decoder = JSONDecoder()
        let request = GaslessTransactionsAPITarget(apiType: apiType, target: target)
        let response = try await provider.asyncRequest(request)
        return try response.mapAPIResponseThrowingTangemAPIError(allowRedirectCodes: false, decoder: decoder)
    }
}
