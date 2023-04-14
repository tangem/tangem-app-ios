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

    private var availabilityState: SwappingAvailabilityState = .idle

    private var swappingItems: SwappingItems {
        didSet { delegate?.swappingManager(self, didUpdate: swappingItems) }
    }

    private weak var delegate: SwappingManagerDelegate?
    private var amount: Decimal?
    private var formattedAmount: String {
        guard let amount else { return "" }

        return String(describing: swappingItems.source.convertToWEI(value: amount))
    }

    private var walletAddress: String? {
        walletDataProvider.getWalletAddress(currency: swappingItems.source)
    }

    private var tokenSwappingAllowanceLimit: Decimal?
    // Cached addresses for check approving transactions
    private var pendingTransactions: [Currency: PendingTransactionState] = [:]
    private var bag: Set<AnyCancellable> = []
    private var refreshTask: Task<Void, Never>?

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

        updateBalances()
    }
}

// MARK: - SwappingManager

extension CommonSwappingManager: SwappingManager {
    func setDelegate(_ delegate: SwappingManagerDelegate) {
        self.delegate = delegate
    }

    func getAvailabilityState() -> SwappingAvailabilityState {
        return availabilityState
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

        guard let tokenSwappingAllowanceLimit else {
            return false
        }

        return amount <= tokenSwappingAllowanceLimit
    }

    func update(swappingItems: SwappingItems) {
        self.swappingItems = swappingItems
        swappingItemsDidChange()
    }

    func update(amount: Decimal?) {
        self.amount = amount
        amountDidChange()
    }

    func refresh(type: SwappingManagerRefreshType) {
        refreshTask?.cancel()
        refreshTask = nil
        if let amount = amount, amount > 0 {
            refreshValues(refreshType: type)
        } else {
            updateState(.idle)
        }
    }

    func didSendApprovingTransaction(swappingTxData: SwappingTransactionData) {
        pendingTransactions[swappingTxData.sourceCurrency] = .pending(destination: swappingTxData.destinationAddress)
        tokenSwappingAllowanceLimit = nil

        refresh(type: .full)
    }

    func didSendSwapTransaction(swappingTxData: SwappingTransactionData) {
        updateState(.idle)
    }
}

// MARK: - Fields Changes

private extension CommonSwappingManager {
    func amountDidChange() {
        updateBalances()

        refresh(type: .full)
    }

    func swappingItemsDidChange() {
        updateState(.idle)
        updateBalances()

        tokenSwappingAllowanceLimit = nil
    }
}

// MARK: - State updates

private extension CommonSwappingManager {
    func updateState(_ state: SwappingAvailabilityState) {
        availabilityState = state
        if Task.isCancelled {
            // Task was cancelled so we don't need to update UI for staled refresh request
            return
        }
        delegate?.swappingManager(self, didUpdate: state)
    }
}

// MARK: - Requests

private extension CommonSwappingManager {
    func refreshValues(refreshType: SwappingManagerRefreshType = .full) {
        updateState(.loading(refreshType))

        refreshTask = Task {
            do {
                guard isEnoughAmountForSwapping() else {
                    try await loadPreview()
                    return
                }

                switch swappingItems.source.currencyType {
                case .coin:
                    try await loadDataForCoinSwapping()
                case .token:
                    try await loadDataForTokenSwapping()
                }
            } catch {
                if Task.isCancelled {
                    return
                }

                updateState(.requiredRefresh(occurredError: error))
            }
        }
    }

    func loadDataForTokenSwapping() async throws {
        try await updateSwappingAmountAllowance()
        try Task.checkCancellation()

        // If allowance is enough just load the data for swap this token
        if isEnoughAllowance() {
            // If we saved pending transaction just remove it
            if hasPendingTransaction() {
                pendingTransactions[swappingItems.source] = nil
            }

            try await loadDataForCoinSwapping()
            return
        }

        // If approving transaction was sent but allowance still zero
        if hasPendingTransaction(), !isEnoughAllowance() {
            try await loadPreview()

            return
        }

        // If haven't allowance and haven't pending transaction just load data for approve
        try await loadApproveData()
    }

    func loadPreview() async throws {
        let preview = try await mapSwappingPreviewData(from: getSwappingQuoteDataModel())
        updateState(.preview(preview))
    }

    func loadDataForCoinSwapping() async throws {
        let swappingData = try await getSwappingTxDataModel()

        try Task.checkCancellation()

        let data = try await mapToSwappingTransactionData(swappingData: swappingData)

        try Task.checkCancellation()

        let result = try await mapToSwappingResultData(transaction: data)

        try Task.checkCancellation()

        updateState(.available(result, data: data))
    }

    func loadApproveData() async throws {
        // We need to load quoteData for "from" and "to" amounts
        async let quoteData = getSwappingQuoteDataModel()
        async let approvedDataModel = getSwappingApprovedDataModel()
        let data = try await mapToSwappingTransactionData(
            quoteData: quoteData,
            approvedData: approvedDataModel
        )

        try Task.checkCancellation()

        let result = try await mapToSwappingResultData(transaction: data)
        updateState(.available(result, data: data))
    }

    func updateSwappingAmountAllowance() async throws {
        guard let walletAddress = walletAddress else {
            throw SwappingManagerError.walletAddressNotFound
        }

        tokenSwappingAllowanceLimit = try await swappingProvider.fetchAmountAllowance(
            for: swappingItems.source,
            walletAddress: walletAddress
        )

        logger.debug("Token \(swappingItems.source) allowanceLimit \(tokenSwappingAllowanceLimit as Any)")
    }

    func getSwappingQuoteDataModel() async throws -> SwappingQuoteDataModel {
        try await swappingProvider.fetchQuote(
            items: swappingItems,
            amount: formattedAmount,
            referrer: referrer
        )
    }

    func getSwappingApprovedDataModel() async throws -> SwappingApprovedDataModel {
        try await swappingProvider.fetchApproveSwappingData(for: swappingItems.source)
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

    func updateBalances() {
        Task {
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
