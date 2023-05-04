//
//  CommonSwappingManager.swift
//  TangemSwapping
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class CommonSwappingManager {
    // MARK: - Dependencies

    private let swappingProvider: SwappingProvider
    private let walletDataProvider: SwappingWalletDataProvider
    private let logger: SwappingLogger
    private let referrer: SwappingReferrerAccount?

    // MARK: - Internal

    private var swappingItems: SwappingItems
    private var amount: Decimal?
    private var approvePolicy: SwappingApprovePolicy = .unlimited
    private var swappingAllowanceLimit: [Currency: Decimal] = [:]
    // Cached addresses for check approving transactions
    private var pendingTransactions: [Currency: PendingTransactionState] = [:]
    private var bag: Set<AnyCancellable> = []

    private var formattedAmount: String {
        guard let amount else { return "" }

        return String(describing: swappingItems.source.convertToWEI(value: amount))
    }

    private var walletAddress: String? {
        walletDataProvider.getWalletAddress(currency: swappingItems.source)
    }

    init(
        swappingProvider: SwappingProvider,
        walletDataProvider: SwappingWalletDataProvider,
        logger: SwappingLogger,
        referrer: SwappingReferrerAccount?,
        swappingItems: SwappingItems,
        amount: Decimal? = nil
    ) {
        self.swappingProvider = swappingProvider
        self.walletDataProvider = walletDataProvider
        self.logger = logger
        self.referrer = referrer
        self.swappingItems = swappingItems
        self.amount = amount

        Task {
            await refreshBalances()
        }
    }
}

// MARK: - SwappingManager

extension CommonSwappingManager: SwappingManager {
    func getAmount() -> Decimal? {
        return amount
    }

    func getSwappingItems() -> SwappingItems {
        return swappingItems
    }

    func getReferrerAccount() -> SwappingReferrerAccount? {
        return referrer
    }

    func isEnoughAllowance() -> Bool {
        guard swappingItems.source.isToken, let amount, amount > 0 else {
            return true
        }

        guard let allowance = swappingAllowanceLimit[swappingItems.source] else {
            return false
        }

        return amount <= allowance
    }

    func update(swappingItems: SwappingItems) {
        self.swappingItems = swappingItems
    }

    func update(amount: Decimal?) {
        self.amount = amount
    }

    func update(approvePolicy: SwappingApprovePolicy) {
        self.approvePolicy = approvePolicy
    }

    func refreshBalances() async -> SwappingItems {
        try? await updateSwappingItemsBalances()
        return swappingItems
    }

    func refresh(type: SwappingManagerRefreshType) async -> SwappingAvailabilityState {
        return await refreshValues(refreshType: type)
    }

    func didSendApprovingTransaction(swappingTxData: SwappingTransactionData) {
        pendingTransactions[swappingTxData.sourceCurrency] = .pending(destination: swappingTxData.destinationAddress)
        swappingAllowanceLimit[swappingTxData.sourceCurrency] = nil
    }
}

// MARK: - Requests

private extension CommonSwappingManager {
    func refreshValues(refreshType: SwappingManagerRefreshType = .full) async -> SwappingAvailabilityState {
        do {
            try await updateSwappingItemsBalances()

            guard isEnoughAmountForSwapping() else {
                return try await loadPreview()
            }

            switch swappingItems.source.currencyType {
            case .coin:
                return try await loadDataForCoinSwapping()
            case .token:
                return try await loadDataForTokenSwapping()
            }
        } catch {
            if Task.isCancelled {
                return .idle
            }

            return .requiredRefresh(occurredError: error)
        }
    }

    func loadDataForTokenSwapping() async throws -> SwappingAvailabilityState {
        try await updateSwappingAmountAllowance()

        try Task.checkCancellation()

        // If allowance is enough just load the data for swap this token
        if isEnoughAllowance() {
            // If we saved pending transaction just remove it
            if hasPendingTransaction() {
                pendingTransactions[swappingItems.source] = nil
            }

            return try await loadDataForCoinSwapping()
        }

        // If approving transaction was sent but allowance still zero
        if hasPendingTransaction(), !isEnoughAllowance() {
            return try await loadPreview()
        }

        // If haven't allowance and haven't pending transaction just load data for approve
        return try await loadApproveData()
    }

    func loadPreview() async throws -> SwappingAvailabilityState {
        return try await .preview(mapSwappingPreviewData(from: getSwappingQuoteDataModel()))
    }

    func loadDataForCoinSwapping() async throws -> SwappingAvailabilityState {
        let swappingData = try await getSwappingTxDataModel()

        try Task.checkCancellation()

        let data = try await mapToSwappingTransactionData(swappingData: swappingData)

        try Task.checkCancellation()

        let result = try await mapToSwappingResultData(transaction: data)

        try Task.checkCancellation()

        return .available(result, data: data)
    }

    func loadApproveData() async throws -> SwappingAvailabilityState {
        // We need to load quoteData for "from" and "to" amounts
        async let quoteData = getSwappingQuoteDataModel()
        async let approvedDataModel = getSwappingApprovedDataModel()
        let data = try await mapToSwappingTransactionData(
            quoteData: quoteData,
            approvedData: approvedDataModel
        )

        try Task.checkCancellation()

        let result = try await mapToSwappingResultData(transaction: data)
        return .available(result, data: data)
    }

    func updateSwappingAmountAllowance() async throws {
        guard let walletAddress = walletAddress else {
            throw SwappingManagerError.walletAddressNotFound
        }

        let allowance = try await swappingProvider.fetchAmountAllowance(
            for: swappingItems.source,
            walletAddress: walletAddress
        )
        swappingAllowanceLimit[swappingItems.source] = allowance

        logger.debug("Token \(swappingItems.source.name) allowance \(allowance)")
    }

    func getSwappingQuoteDataModel() async throws -> SwappingQuoteDataModel {
        try await swappingProvider.fetchQuote(
            items: swappingItems,
            amount: formattedAmount,
            referrer: referrer
        )
    }

    func getSwappingApprovedDataModel() async throws -> SwappingApprovedDataModel {
        try await swappingProvider.fetchApproveSwappingData(
            for: swappingItems.source,
            approvePolicy: approvePolicy
        )
    }

    func getSwappingTxDataModel() async throws -> SwappingDataModel {
        guard let walletAddress else {
            throw SwappingManagerError.walletAddressNotFound
        }

        return try await swappingProvider.fetchSwappingData(
            items: swappingItems,
            walletAddress: walletAddress,
            amount: formattedAmount,
            referrer: referrer
        )
    }

    func updateSwappingItemsBalances() async throws {
        let source = swappingItems.source
        let balance = try await walletDataProvider.getBalance(for: source)

        if let destination = swappingItems.destination {
            let balance = try await walletDataProvider.getBalance(for: destination)
            if swappingItems.destinationBalance != balance {
                swappingItems.destinationBalance = balance
            }
        }

        if swappingItems.sourceBalance != balance {
            swappingItems.sourceBalance = balance
        }
    }

    func isEnoughAmountForSwapping() -> Bool {
        guard let sendValue = amount else {
            return true
        }

        return swappingItems.sourceBalance >= sendValue
    }

    func hasPendingTransaction() -> Bool {
        pendingTransactions[swappingItems.source] != nil
    }
}

// MARK: - Mapping

private extension CommonSwappingManager {
    func mapSwappingPreviewData(from quoteData: SwappingQuoteDataModel) throws -> SwappingPreviewData {
        guard let destination = swappingItems.destination else {
            throw SwappingManagerError.destinationNotFound
        }

        let expectedAmount = destination.convertFromWEI(value: quoteData.toTokenAmount)

        return SwappingPreviewData(
            expectedAmount: expectedAmount,
            isPermissionRequired: !isEnoughAllowance(),
            hasPendingTransaction: hasPendingTransaction(),
            isEnoughAmountForSwapping: isEnoughAmountForSwapping()
        )
    }

    func mapToSwappingResultData(transaction: SwappingTransactionData) async throws -> SwappingResultData {
        let source = swappingItems.source
        let sourceBalance = swappingItems.sourceBalance
        let fee = transaction.fee

        let isEnoughAmountForFee: Bool
        var paymentAmount = transaction.sourceCurrency.convertFromWEI(value: transaction.sourceAmount)
        let receivedAmount = transaction.destinationCurrency.convertFromWEI(value: transaction.destinationAmount)
        switch swappingItems.source.currencyType {
        case .coin:
            paymentAmount += fee
            isEnoughAmountForFee = sourceBalance >= fee
        case .token:
            let coinBalance = try await walletDataProvider.getBalance(for: source.blockchain)
            isEnoughAmountForFee = coinBalance >= fee
        }

        let isEnoughAmountForSwapping = sourceBalance >= paymentAmount

        return SwappingResultData(
            amount: receivedAmount,
            fee: fee,
            isEnoughAmountForSwapping: isEnoughAmountForSwapping,
            isEnoughAmountForFee: isEnoughAmountForFee,
            isPermissionRequired: !isEnoughAllowance()
        )
    }

    func mapToSwappingTransactionData(swappingData: SwappingDataModel) async throws -> SwappingTransactionData {
        guard let destination = swappingItems.destination else {
            throw SwappingManagerError.destinationNotFound
        }

        let value = swappingItems.source.convertFromWEI(value: swappingData.value)
        let gasModel = try await walletDataProvider.getGasModel(
            sourceAddress: swappingData.sourceAddress,
            destinationAddress: swappingData.destinationAddress,
            data: swappingData.txData,
            blockchain: swappingItems.source.blockchain,
            value: value
        )

        return SwappingTransactionData(
            sourceCurrency: swappingItems.source,
            sourceBlockchain: swappingItems.source.blockchain,
            destinationCurrency: destination,
            sourceAddress: swappingData.sourceAddress,
            destinationAddress: swappingData.destinationAddress,
            txData: swappingData.txData,
            sourceAmount: swappingData.sourceCurrencyAmount,
            destinationAmount: swappingData.destinationCurrencyAmount,
            value: value,
            gas: gasModel
        )
    }

    func mapToSwappingTransactionData(
        quoteData: SwappingQuoteDataModel,
        approvedData: SwappingApprovedDataModel
    ) async throws -> SwappingTransactionData {
        guard let destination = swappingItems.destination else {
            throw SwappingManagerError.destinationNotFound
        }

        guard let walletAddress = walletAddress else {
            throw SwappingManagerError.walletAddressNotFound
        }

        let value = swappingItems.source.convertFromWEI(value: approvedData.value)
        let gasModel = try await walletDataProvider.getGasModel(
            sourceAddress: walletAddress,
            destinationAddress: approvedData.tokenAddress,
            data: approvedData.data,
            blockchain: swappingItems.source.blockchain,
            value: value
        )

        return SwappingTransactionData(
            sourceCurrency: swappingItems.source,
            sourceBlockchain: swappingItems.source.blockchain,
            destinationCurrency: destination,
            sourceAddress: walletAddress,
            destinationAddress: approvedData.tokenAddress,
            txData: approvedData.data,
            sourceAmount: quoteData.fromTokenAmount,
            destinationAmount: quoteData.toTokenAmount,
            value: approvedData.value,
            gas: gasModel
        )
    }
}

extension CommonSwappingManager {
    enum PendingTransactionState: Hashable {
        case pending(destination: String)
    }
}
