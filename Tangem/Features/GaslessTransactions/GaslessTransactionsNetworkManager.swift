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
    typealias GaslessTransaction = GaslessTransactionsDTO.Request.GaslessTransaction

    var availableFeeTokens: [FeeToken] { get }
    var availableFeeTokensPublisher: AnyPublisher<[FeeToken], Never> { get }

    var currentHost: String { get }

    func updateAvailableTokens()
    func sendGaslessTransaction(_ transaction: GaslessTransaction) async throws -> String
    func initialize()

    var feeRecipientAddress: String? { get }
    /// Fire-and-forget variant for environments without an async context.
    /// We need this version to kick off fetching the fee recipient address early (e.g. during app startup)
    func preloadFeeRecipientAddress()
}

final class CommonGaslessTransactionsNetworkManager {
    private let apiService: GaslessTransactionsAPIService
    private let availableFeeTokensSubject = CurrentValueSubject<[FeeToken], Never>([])
    private var fetchFeeTokensTask: Task<Void, Never>?
    private var _feeRecipientAddress: String?

    init(apiService: GaslessTransactionsAPIService) {
        self.apiService = apiService
    }
}

// MARK: - GaslessTransactionsNetworkManager

extension CommonGaslessTransactionsNetworkManager: GaslessTransactionsNetworkManager {
    var currentHost: String {
        AppEnvironment.current.isProduction ?
            GaslessApiTargetConstants.prodBaseURL.absoluteString :
            GaslessApiTargetConstants.devBaseURL.absoluteString
    }

    var feeRecipientAddress: String? {
        _feeRecipientAddress
    }

    var availableFeeTokens: [FeeToken] {
        availableFeeTokensSubject.value
    }

    var availableFeeTokensPublisher: AnyPublisher<[FeeToken], Never> {
        availableFeeTokensSubject.eraseToAnyPublisher()
    }

    func initialize() {
        updateAvailableTokens()
        preloadFeeRecipientAddress()
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

    func sendGaslessTransaction(_ transaction: GaslessTransaction) async throws -> String {
        try await apiService.sendGaslessTransaction(transaction)
    }

    func preloadFeeRecipientAddress() {
        Task { [weak self] in
            self?._feeRecipientAddress = try await self?.apiService.getFeeRecipientAddress()
        }
    }
}

private struct GaslessTransactionsNetworkManagerKey: InjectionKey {
    static var currentValue: GaslessTransactionsNetworkManager = {
        let apiType: GaslessTransactionsAPIType = AppEnvironment.current.isProduction
            ? .prod
            : FeatureStorage.instance.gaslessTransactionsAPIType

        let provider: TangemProvider<GaslessTransactionsAPITarget> = .init(
            plugins: [GaslessTransactionsAuthorizationPlugin()],
            sessionConfiguration: .gaslessConfiguration
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
