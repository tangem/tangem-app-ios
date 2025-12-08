//
//  YieldManagerInteractor.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import BlockchainSdk

actor YieldManagerInteractor {
    private(set) var enterFee: YieldTransactionFee?
    private var exitFee: YieldTransactionFee?
    private var approveFee: YieldTransactionFee?

    private var enterFeeTask: Task<YieldTransactionFee, Error>?
    private var exitFeeTask: Task<YieldTransactionFee, Error>?
    private var approveFeeTask: Task<YieldTransactionFee, Error>?

    // MARK: - Dependencies

    private let transactionDispatcher: any TransactionDispatcher
    private let manager: YieldModuleManager
    private let yieldModuleNotificationInteractor: YieldModuleNoticeInteractor

    // MARK: - Init

    init(
        transactionDispatcher: any TransactionDispatcher,
        manager: YieldModuleManager,
        yieldModuleNotificationInteractor: YieldModuleNoticeInteractor
    ) {
        self.transactionDispatcher = transactionDispatcher
        self.manager = manager
        self.yieldModuleNotificationInteractor = yieldModuleNotificationInteractor
    }

    // MARK: - Public Implementation

    func isGasPriceHigh(in fee: YieldTransactionFee) -> Bool {
        return fee.maxFeePerGas?.decimal ?? .zero > Constants.maxFeePerGasLimitWei
    }

    func getAvailableBalance() -> Decimal? {
        manager.state?.state.activeInfo?.yieldModuleBalanceValue
    }

    func getIsApproveRequired() -> Bool {
        guard case .active(let info) = manager.state?.state else {
            return false
        }

        return info.isAllowancePermissionRequired
    }

    func getUndepositedAmounts() -> Decimal? {
        guard case .active(let info) = manager.state?.state, !info.nonYieldModuleBalanceValue.isZero else {
            return nil
        }

        return info.nonYieldModuleBalanceValue
    }

    func getApy() async throws -> Decimal {
        if let apy = manager.state?.marketInfo?.apy {
            return apy
        } else {
            let info = try await manager.fetchYieldTokenInfo()
            return info.apy
        }
    }

    func getMaxFeeNative() -> Decimal? {
        if let marketInfo = manager.state?.marketInfo, let maxFeeNative = marketInfo.maxFeeNative {
            return maxFeeNative
        }

        return nil
    }

    func getChartData() async throws -> YieldChartData {
        try await manager.fetchChartData()
    }

    func getCurrentFeeParameters() async throws -> EthereumFeeParameters {
        try await manager.currentNetworkFeeParameters()
    }

    func getMinAmount(feeParameters: EthereumFeeParameters) async throws -> Decimal {
        let converter = BalanceConverter()

        let feeNative = feeParameters.calculateFee(decimalValue: manager.blockchain.decimalValue)
        let gasInFiat = try await converter.convertToFiat(feeNative, currencyId: manager.blockchain.currencyId)

        guard let gasInToken = converter.convertFromFiat(gasInFiat, currencyId: manager.tokenId) else {
            throw YieldModuleError.minimalTopUpAmountNotFound
        }

        let feeBuffered = gasInToken * Constants.minimalTopUpBuffer
        let minAmount = feeBuffered / Constants.minimalTopUpFeeLimit

        let minAmountInFiat = try await converter.convertToFiat(minAmount, currencyId: manager.tokenId)
        return minAmountInFiat
    }

    func getCurrentNetworkFee(feeParameters: EthereumFeeParameters) async throws -> Decimal {
        let converter = BalanceConverter()

        let feeNative = feeParameters.calculateFee(decimalValue: manager.blockchain.decimalValue)
        let gasInFiat = try await converter.convertToFiat(feeNative, currencyId: manager.blockchain.currencyId)
        return gasInFiat
    }

    func clearAll() {
        enterFee = nil
        exitFee = nil
        approveFee = nil
        enterFeeTask = nil
        exitFeeTask = nil
        approveFeeTask = nil
    }

    func getEnterFee() async throws -> YieldTransactionFee {
        try await loadFee(
            getTask: { enterFeeTask },
            setTask: { enterFeeTask = $0 },
            setCache: { enterFee = $0 },
            loader: {
                try await self.manager.enterFee()
            }
        )
    }

    func getApproveFee() async throws -> YieldTransactionFee {
        try await loadFee(
            getTask: { approveFeeTask },
            setTask: { approveFeeTask = $0 },
            setCache: { approveFee = $0 },
            loader: {
                try await self.manager.approveFee()
            }
        )
    }

    func getExitFee() async throws -> YieldTransactionFee {
        try await loadFee(
            getTask: { exitFeeTask },
            setTask: { exitFeeTask = $0 },
            setCache: { exitFee = $0 },
            loader: {
                try await self.manager.exitFee()
            }
        )
    }

    func approve(with token: TokenItem) async throws {
        guard let fee = approveFee else {
            throw YieldModuleError.feeNotFound
        }

        _ = try await manager.approve(fee: fee, transactionDispatcher: transactionDispatcher)
    }

    func enter(with token: TokenItem) async throws {
        guard let fee = enterFee else {
            throw YieldModuleError.feeNotFound
        }

        _ = try await manager.enter(fee: fee, transactionDispatcher: transactionDispatcher)
        await yieldModuleNotificationInteractor.markWithdrawalAlertShouldShow(for: token)
    }

    func exit(with token: TokenItem) async throws {
        guard let fee = exitFee else {
            throw YieldModuleError.feeNotFound
        }

        _ = try await manager.exit(fee: fee, transactionDispatcher: transactionDispatcher)
        await yieldModuleNotificationInteractor.deleteWithdrawalAlert(for: token)
    }

    // MARK: - Heplers

    private func loadFee(
        getTask: () -> Task<YieldTransactionFee, Error>?,
        setTask: (Task<YieldTransactionFee, Error>?) -> Void,
        setCache: (YieldTransactionFee) -> Void,
        loader: @Sendable @escaping () async throws -> YieldTransactionFee
    ) async throws -> YieldTransactionFee {
        if let existing = getTask() {
            let fee = try await existing.value
            setCache(fee)
            return fee
        }

        let new = Task { try await loader() }
        setTask(new)

        defer {
            setTask(nil)
        }

        do {
            let fee = try await new.value
            setCache(fee)
            return fee
        } catch {
            throw error
        }
    }
}

private extension YieldManagerInteractor {
    enum Constants {
        static let minimalTopUpBuffer: Decimal = 1.25
        static let minimalTopUpFeeLimit: Decimal = 0.04
        static let maxFeePerGasLimitWei: Decimal = 4000000000
    }
}
