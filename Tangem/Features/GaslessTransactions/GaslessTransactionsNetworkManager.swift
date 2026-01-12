//
//  GaslessTransactionsNetworkManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import TangemNetworkUtils

protocol GaslessTransactionsNetworkManager {
    typealias FeeToken = GaslessTransactionsDTO.Response.FeeToken
    typealias MetaTransaction = GaslessTransactionsDTO.Request.GaslessTransaction
    typealias SignResult = GaslessTransactionsDTO.Response.SignResponse.Result

    var availableFeeTokens: [FeeToken] { get }
    var availableFeeTokensPublisher: AnyPublisher<[FeeToken], Never> { get }

    func updateAvailableTokens()
    func signGaslessTransaction(_ transaction: MetaTransaction) async throws -> SignResult
}

final class CommonGaslessTransactionsNetworkManager {
    private let apiService: GaslessTransactionsAPIService
    private let availableFeeTokensSubject = CurrentValueSubject<[FeeToken], Never>([])
    private var fetchFeeTokensTask: Task<Void, Never>?

    init(apiService: GaslessTransactionsAPIService) {
        self.apiService = apiService
    }
}

// MARK: - GaslessTransactionsNetworkManager

extension CommonGaslessTransactionsNetworkManager: GaslessTransactionsNetworkManager {
    var availableFeeTokens: [FeeToken] {
        availableFeeTokensSubject.value
    }

    var availableFeeTokensPublisher: AnyPublisher<[FeeToken], Never> {
        availableFeeTokensSubject.eraseToAnyPublisher()
    }

    func updateAvailableTokens() {
        if fetchFeeTokensTask != nil {
            fetchFeeTokensTask?.cancel()
        }

        let fetchFeeTokensTask = Task {
            defer { self.fetchFeeTokensTask = nil }

            do {
                let availableTokens = try await apiService.getAvailableTokens()
                try Task.checkCancellation()
                availableFeeTokensSubject.send(availableTokens)
            } catch is CancellationError {
                AppLogger.debug("Fetching gasless fee tokens was cancelled")
            } catch {
                AppLogger.error("Failed to fetch available gasless fee tokens", error: error)
            }
        }

        self.fetchFeeTokensTask = fetchFeeTokensTask
    }

    func signGaslessTransaction(_ transaction: MetaTransaction) async throws -> SignResult {
        try await apiService.signGaslessTransaction(transaction)
    }
}

private struct GaslessTransactionsNetworkManagerKey: InjectionKey {
    static var currentValue: GaslessTransactionsNetworkManager = {
        let apiType: GaslessTransactionsAPIType = AppEnvironment.current.isProduction
            ? .prod
            : FeatureStorage.instance.gaslessTransactionsAPIType

        let provider: TangemProvider<GaslessTransactionsAPITarget> = .init(
            configuration: .ephemeralConfiguration,
            additionalPlugins: [
                GaslessTransactionsAuthorizationPlugin(),
            ]
        )

        let manager = CommonGaslessTransactionsNetworkManager(
            apiService: CommonGaslessTransactionAPIService(provider: provider, apiType: apiType)
        )

        return manager
    }()
}

extension InjectedValues {
    var gaslessTransactionsNetworkManager: GaslessTransactionsNetworkManager {
        get { Self[GaslessTransactionsNetworkManagerKey.self] }
        set { Self[GaslessTransactionsNetworkManagerKey.self] = newValue }
    }
}
