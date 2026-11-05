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
import enum BlockchainSdk.GaslessExecutorVersion

protocol GaslessTransactionsNetworkManager {
    typealias FeeToken = GaslessTransactionsDTO.Response.FeeToken
    typealias TronFeeToken = GaslessTransactionsDTO.Response.TronFeeToken
    typealias GaslessTransaction = GaslessTransactionsDTO.Request.GaslessTransaction
    typealias GaslessBatchTransaction = GaslessTransactionsDTO.Request.GaslessBatchTransaction
    typealias TronEstimateRequest = GaslessTransactionsDTO.Request.TronEstimate
    typealias TronEstimateResponse = GaslessTransactionsDTO.Response.TronEstimate
    typealias TronSubmitRequest = GaslessTransactionsDTO.Request.TronSubmit
    typealias TronSubmitResponse = GaslessTransactionsDTO.Response.TronSubmit
    typealias SolanaSubmitRequest = GaslessTransactionsDTO.Request.SolanaSubmit

    var availableFeeTokens: [FeeToken] { get }
    var availableTronFeeTokens: [TronFeeToken] { get }

    var currentHost: String { get }

    func updateAvailableTokens()
    func sendGaslessTransaction(_ transaction: GaslessTransaction, executorVersion: GaslessExecutorVersion) async throws -> String
    func sendGaslessBatchTransaction(_ transaction: GaslessBatchTransaction) async throws -> String
    func estimateTronGaslessTransaction(
        _ request: TronEstimateRequest,
        userWalletId: UserWalletId
    ) async throws -> TronEstimateResponse
    func submitTronGaslessTransaction(
        _ request: TronSubmitRequest,
        userWalletId: UserWalletId
    ) async throws -> TronSubmitResponse
    func initialize()

    var cachedFeeRecipientAddress: String? { get }
    var feeRecipientAddress: String? { get async }

    var cachedSolanaFeePayer: String? { get }
    var solanaFeePayer: String? { get async }
    func submitSolanaGaslessTransaction(_ request: SolanaSubmitRequest, userWalletId: UserWalletId) async throws -> String
}

final class CommonGaslessTransactionsNetworkManager {
    private let apiService: GaslessTransactionsAPIService
    private let availableFeeTokensSubject = CurrentValueSubject<[FeeToken], Never>([])
    private let availableTronFeeTokensSubject = CurrentValueSubject<[TronFeeToken], Never>([])
    private var fetchFeeTokensTask: Task<Void, Never>?
    private var fetchTronFeeTokensTask: Task<Void, Never>?
    private var feeRecipientTask: Task<String?, Never>?

    private let _feeRecipientAddress = OSAllocatedUnfairLock<String?>(initialState: nil)
    private let solanaFeePayerState = OSAllocatedUnfairLock(initialState: SolanaFeePayerState())

    init(apiService: GaslessTransactionsAPIService) {
        self.apiService = apiService
    }
}

// MARK: - GaslessTransactionsNetworkManager

extension CommonGaslessTransactionsNetworkManager: GaslessTransactionsNetworkManager {
    var cachedFeeRecipientAddress: String? {
        _feeRecipientAddress.withLock { $0 }
    }

    var currentHost: String {
        AppEnvironment.current.isProduction ?
            GaslessApiTargetConstants.prodBaseURL.absoluteString :
            GaslessApiTargetConstants.devBaseURL.absoluteString
    }

    var feeRecipientAddress: String? {
        get async {
            if let cached = cachedFeeRecipientAddress {
                return cached
            }
            if let task = feeRecipientTask {
                return await task.value
            }

            let task = Task<String?, Never> {
                do {
                    let address = try await apiService.getFeeRecipientAddress()
                    _feeRecipientAddress.withLock { $0 = address }
                    return address
                } catch {
                    AppLogger.error("Failed to fetch fee recipient address", error: error)
                    return nil
                }
            }
            feeRecipientTask = task
            let value = await task.value
            feeRecipientTask = nil
            return value
        }
    }

    var availableFeeTokens: [FeeToken] {
        availableFeeTokensSubject.value
    }

    var availableTronFeeTokens: [TronFeeToken] {
        availableTronFeeTokensSubject.value
    }

    func initialize() {
        updateAvailableTokens()
        preloadFeeRecipientAddress()

        if FeatureProvider.isAvailable(.solanaGasless) {
            preloadSolanaFeePayer()
        }
    }

    var cachedSolanaFeePayer: String? {
        solanaFeePayerState.withLock { $0.address }
    }

    var solanaFeePayer: String? {
        get async {
            let task: Task<String?, Never> = solanaFeePayerState.withLock { state in
                if let address = state.address {
                    return Task { address }
                }

                if let task = state.task {
                    return task
                }

                let task = Task<String?, Never> { [weak self] in
                    await self?.loadSolanaFeePayer()
                }
                state.task = task
                return task
            }

            return await task.value
        }
    }

    func submitSolanaGaslessTransaction(_ request: SolanaSubmitRequest, userWalletId: UserWalletId) async throws -> String {
        try await apiService.submitSolanaGaslessTransaction(request, userWalletId: userWalletId)
    }

    func updateAvailableTokens() {
        updateAvailableFeeTokens()
        updateAvailableTronFeeTokens()
    }

    func sendGaslessTransaction(_ transaction: GaslessTransaction, executorVersion: GaslessExecutorVersion) async throws -> String {
        try await apiService.sendGaslessTransaction(transaction, executorVersion: executorVersion)
    }

    func sendGaslessBatchTransaction(_ transaction: GaslessBatchTransaction) async throws -> String {
        try await apiService.sendGaslessBatchTransaction(transaction)
    }

    func estimateTronGaslessTransaction(
        _ request: TronEstimateRequest,
        userWalletId: UserWalletId
    ) async throws -> TronEstimateResponse {
        try await mapTronActivationError {
            try await apiService.estimateTronGaslessTransaction(request, userWalletId: userWalletId)
        }
    }

    func submitTronGaslessTransaction(
        _ request: TronSubmitRequest,
        userWalletId: UserWalletId
    ) async throws -> TronSubmitResponse {
        try await mapTronActivationError {
            try await apiService.submitTronGaslessTransaction(request, userWalletId: userWalletId)
        }
    }

    func preloadFeeRecipientAddress() {
        _ = Task { [weak self] in
            let address = try await self?.apiService.getFeeRecipientAddress()
            self?._feeRecipientAddress.withLock { $0 = address }
        }
    }
}

// MARK: - Private

private extension CommonGaslessTransactionsNetworkManager {
    func updateAvailableFeeTokens() {
        fetchFeeTokensTask?.cancel()

        let fetchFeeTokensTask = Task {
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

    func mapTronActivationError<T>(_ work: () async throws -> T) async throws -> T {
        do {
            return try await work()
        } catch let error as TangemAPIError {
            throw GaslessTransactionsDTO.APIError.TronActivation(apiError: error) ?? error
        }
    }

    func updateAvailableTronFeeTokens() {
        fetchTronFeeTokensTask?.cancel()

        let fetchTronFeeTokensTask = Task {
            do {
                let availableTokens = try await apiService.getAvailableTronTokens()
                try Task.checkCancellation()
                availableTronFeeTokensSubject.send(availableTokens)
            } catch is CancellationError {
                AppLogger.debug("Fetching Tron gasless fee tokens was cancelled")
            } catch {
                AppLogger.error("Failed to fetch available Tron gasless fee tokens", error: error)
            }
        }

        self.fetchTronFeeTokensTask = fetchTronFeeTokensTask
    }

    func preloadSolanaFeePayer() {
        _ = Task { [weak self] in
            _ = await self?.solanaFeePayer
        }
    }

    func loadSolanaFeePayer() async -> String? {
        do {
            let address = try await apiService.getSolanaFeePayer()
            solanaFeePayerState.withLock { state in
                state.address = address
                state.task = nil
            }
            return address
        } catch {
            AppLogger.error("Failed to fetch Solana gasless fee payer", error: error)
            solanaFeePayerState.withLock { $0.task = nil }
            return nil
        }
    }
}

private struct SolanaFeePayerState {
    var address: String?
    var task: Task<String?, Never>?
}

private struct GaslessTransactionsNetworkManagerKey: InjectionKey {
    static var currentValue: GaslessTransactionsNetworkManager = {
        let apiType: GaslessTransactionsAPIType = {
            if AppEnvironment.current.isProduction {
                return .prod
            }
            if FeatureStorage.instance.tangemAPIType == .mock {
                return .mock
            }
            return FeatureStorage.instance.gaslessTransactionsAPIType
        }()

        let provider = TangemProvider<GaslessTransactionsAPITarget>(
            configuration: TangemProviderConfiguration(
                logOptions: .verbose,
                urlSessionConfiguration: .gaslessConfiguration
            ),
            additionalPlugins: [
                DeviceInfoPlugin(),
                GaslessTransactionsAuthorizationPlugin(),
                TimeoutIntervalPlugin(),
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
