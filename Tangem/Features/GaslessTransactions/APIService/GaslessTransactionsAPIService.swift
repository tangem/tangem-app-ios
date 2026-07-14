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
    typealias GaslessTransaction = GaslessTransactionsDTO.Request.GaslessTransaction
    typealias GaslessBatchTransaction = GaslessTransactionsDTO.Request.GaslessBatchTransaction
    typealias SendResponse = GaslessTransactionsDTO.Response.SendResponse
    typealias TronEstimateRequest = GaslessTransactionsDTO.Request.TronEstimate
    typealias TronEstimateResponse = GaslessTransactionsDTO.Response.TronEstimate
    typealias TronSubmitRequest = GaslessTransactionsDTO.Request.TronSubmit
    typealias TronSubmitResponse = GaslessTransactionsDTO.Response.TronSubmit

    func getAvailableTokens() async throws -> [FeeToken]
    func getAvailableTronTokens() async throws -> [FeeToken]
    // Sends a constructed transaction to the backend, which submits it and returns the transaction hash
    func sendGaslessTransaction(_ transaction: GaslessTransactionsDTO.Request.GaslessTransaction) async throws -> String
    func sendGaslessBatchTransaction(_ transaction: GaslessTransactionsDTO.Request.GaslessBatchTransaction) async throws -> String
    func getFeeRecipientAddress() async throws -> String
    func estimateTronGaslessTransaction(_ request: TronEstimateRequest) async throws -> TronEstimateResponse
    func submitTronGaslessTransaction(_ request: TronSubmitRequest) async throws -> TronSubmitResponse
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
        let response: GaslessTransactionsDTO.Response.FeeTokens = try await request(for: .availableTokens)
        return response.tokens
    }

    func getAvailableTronTokens() async throws -> [FeeToken] {
        let response: GaslessTransactionsDTO.Response.TronTokens = try await request(for: .tronTokens)
        return response.tokens
    }

    func sendGaslessTransaction(_ transaction: GaslessTransaction) async throws -> String {
        let response: GaslessTransactionsDTO.Response.SendResponse = try await request(for: .sendGaslessTransaction(transaction: transaction))
        return response.txHash
    }

    func sendGaslessBatchTransaction(_ transaction: GaslessBatchTransaction) async throws -> String {
        let response: GaslessTransactionsDTO.Response.SendResponse = try await request(for: .sendGaslessBatchTransaction(transaction: transaction))
        return response.txHash
    }

    func getFeeRecipientAddress() async throws -> String {
        let response: GaslessTransactionsDTO.Response.FeeRecipientResponse = try await request(for: .feeRecipient)
        return response.feeRecipientAddress
    }

    func estimateTronGaslessTransaction(_ request: TronEstimateRequest) async throws -> TronEstimateResponse {
        try await self.request(for: .tronEstimate(request: request))
    }

    func submitTronGaslessTransaction(_ request: TronSubmitRequest) async throws -> TronSubmitResponse {
        try await self.request(for: .tronSubmit(request: request))
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
