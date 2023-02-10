//
//  DefaultExchangeManager.swift
//  TangemExchange
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class DefaultExchangeManager {
    // MARK: - Dependencies

    private let exchangeProvider: ExchangeProvider
    private let blockchainDataProvider: BlockchainDataProvider
    private let logger: ExchangeLogger

    // MARK: - Internal

    private var availabilityState: ExchangeAvailabilityState = .idle {
        didSet { delegate?.exchangeManager(self, didUpdate: availabilityState) }
    }

    private var exchangeItems: ExchangeItems {
        didSet { delegate?.exchangeManager(self, didUpdate: exchangeItems) }
    }

    private weak var delegate: ExchangeManagerDelegate?
    private var amount: Decimal?
    private var formattedAmount: String {
        guard let amount else { return "" }

        return String(describing: exchangeItems.source.convertToWEI(value: amount))
    }

    private var walletAddress: String? {
        blockchainDataProvider.getWalletAddress(currency: exchangeItems.source)
    }

    private var tokenExchangeAllowanceLimit: Decimal?
    // Cached addresses for check approving transactions
    private var pendingTransactions: [Currency: PendingTransactionState] = [:]

    private var bag: Set<AnyCancellable> = []

    init(
        exchangeProvider: ExchangeProvider,
        blockchainInfoProvider: BlockchainDataProvider,
        logger: ExchangeLogger,
        exchangeItems: ExchangeItems,
        amount: Decimal? = nil
    ) {
        self.exchangeProvider = exchangeProvider
        blockchainDataProvider = blockchainInfoProvider
        self.logger = logger
        self.exchangeItems = exchangeItems
        self.amount = amount

        updateBalances()
    }
}

// MARK: - ExchangeManager

extension DefaultExchangeManager: ExchangeManager {
    func setDelegate(_ delegate: ExchangeManagerDelegate) {
        self.delegate = delegate
    }

    func getAvailabilityState() -> ExchangeAvailabilityState {
        return availabilityState
    }

    func getExchangeItems() -> ExchangeItems {
        return exchangeItems
    }

    func isEnoughAllowance() -> Bool {
        guard exchangeItems.source.isToken, let amount, amount > 0 else {
            return true
        }

        guard let tokenExchangeAllowanceLimit else {
            return false
        }

        return amount <= tokenExchangeAllowanceLimit
    }

    func update(exchangeItems: ExchangeItems) {
        self.exchangeItems = exchangeItems
        exchangeItemsDidChange()
    }

    func update(amount: Decimal?) {
        self.amount = amount
        amountDidChange()
    }

    func refresh(type: ExchangeManagerRefreshType) {
        if let amount = amount, amount > 0 {
            refreshValues(refreshType: type)
        } else {
            updateState(.idle)
        }
    }

    func didSendApprovingTransaction(exchangeTxData: ExchangeTransactionDataModel) {
        pendingTransactions[exchangeTxData.sourceCurrency] = .pending(destination: exchangeTxData.destinationAddress)
        tokenExchangeAllowanceLimit = nil

        refresh(type: .full)
    }

    func didSendSwapTransaction(exchangeTxData: ExchangeTransactionDataModel) {
        updateState(.idle)
    }
}

// MARK: - Fields Changes

private extension DefaultExchangeManager {
    func amountDidChange() {
        updateBalances()

        refresh(type: .full)
    }

    func exchangeItemsDidChange() {
        updateState(.idle)
        updateBalances()

        tokenExchangeAllowanceLimit = nil
    }
}

// MARK: - State updates

private extension DefaultExchangeManager {
    func updateState(_ state: ExchangeAvailabilityState) {
        availabilityState = state
    }
}

// MARK: - Requests

private extension DefaultExchangeManager {
    func refreshValues(refreshType: ExchangeManagerRefreshType = .full) {
        updateState(.loading(refreshType))

        Task {
            do {
                let quoteData = try await getQuoteDataModel()
                let preview = try await mapPreviewSwappingDataModel(from: quoteData)

                switch exchangeItems.source.currencyType {
                case .coin:
                    try await loadExchangeData(preview: preview)

                case .token:
                    guard preview.isEnoughAmountForExchange else {
                        updateState(.preview(preview))
                        return
                    }

                    await updateExchangeAmountAllowance()

                    // Check if permission required
                    guard !isEnoughAllowance() else {
                        try await loadExchangeData(preview: preview)
                        return
                    }

                    try await loadApproveData(preview: preview, quoteData: quoteData)
                }
            } catch {
                updateState(.requiredRefresh(occurredError: error))
            }
        }
    }

    func loadExchangeData(preview: PreviewSwappingDataModel) async throws {
        guard preview.isEnoughAmountForExchange else {
            updateState(.preview(preview))
            return
        }

        let exchangeData = try await getExchangeTxDataModel()
        let info = try mapToExchangeTransactionInfo(exchangeData: exchangeData)
        let result = try await mapToSwappingResultDataModel(preview: preview, transaction: info)
        updateState(.available(result, info: info))
    }

    func loadApproveData(preview: PreviewSwappingDataModel, quoteData: QuoteDataModel) async throws {
        // If approving transaction isn't send
        if preview.hasPendingTransaction {
            await updateExchangeAmountAllowance()

            if isEnoughAllowance() {
                /// If we get enough allowance
                pendingTransactions[exchangeItems.source] = nil
                refreshValues()
            } else {
                updateState(.preview(preview))
            }

            return
        }

        let approvedDataModel = try await getExchangeApprovedDataModel()
        let info = try mapToExchangeTransactionInfo(
            quoteData: quoteData,
            approvedData: approvedDataModel
        )

        let result = try await mapToSwappingResultDataModel(preview: preview, transaction: info)
        updateState(.available(result, info: info))
    }

    func hasPendingApprovingTransaction() async throws -> Bool {
        pendingTransactions[exchangeItems.source] != nil
    }

    func updateExchangeAmountAllowance() async {
        // If allowance limit already loaded just call delegate method
        guard let walletAddress else {
            return
        }

        do {
            tokenExchangeAllowanceLimit = try await exchangeProvider.fetchAmountAllowance(
                for: exchangeItems.source,
                walletAddress: walletAddress
            )

            logger.debug("Token \(exchangeItems.source) allowanceLimit \(tokenExchangeAllowanceLimit as Any)")
        } catch {
            tokenExchangeAllowanceLimit = nil
            updateState(.requiredRefresh(occurredError: error))
        }
    }

    func getQuoteDataModel() async throws -> QuoteDataModel {
        try await exchangeProvider.fetchQuote(
            items: exchangeItems,
            amount: formattedAmount
        )
    }

    func getExchangeApprovedDataModel() async throws -> ExchangeApprovedDataModel {
        try await exchangeProvider.fetchApproveExchangeData(for: exchangeItems.source)
    }

    func getExchangeTxDataModel() async throws -> ExchangeDataModel {
        guard let walletAddress else {
            throw ExchangeManagerError.walletAddressNotFound
        }

        return try await exchangeProvider.fetchExchangeData(
            items: exchangeItems,
            walletAddress: walletAddress,
            amount: formattedAmount
        )
    }

    func updateBalances() {
        Task {
            let source = exchangeItems.source
            let balance = try await blockchainDataProvider.getBalance(for: source)

            if let destination = exchangeItems.destination {
                let balance = try await blockchainDataProvider.getBalance(for: destination)
                if exchangeItems.destinationBalance != balance {
                    exchangeItems.destinationBalance = balance
                }
            }

            if exchangeItems.sourceBalance != balance {
                exchangeItems.sourceBalance = balance
            }
        }
    }
}

// MARK: - Mapping

private extension DefaultExchangeManager {
    func mapPreviewSwappingDataModel(from quoteData: QuoteDataModel) async throws -> PreviewSwappingDataModel {
        guard let destination = exchangeItems.destination else {
            throw ExchangeManagerError.destinationNotFound
        }

        let paymentAmount = exchangeItems.source.convertFromWEI(value: quoteData.fromTokenAmount)
        let expectedAmount = destination.convertFromWEI(value: quoteData.toTokenAmount)
        let hasPendingTransaction = try await hasPendingApprovingTransaction()
        let isEnoughAmountForExchange = exchangeItems.sourceBalance >= paymentAmount

        return PreviewSwappingDataModel(
            expectedAmount: expectedAmount,
            isPermissionRequired: !isEnoughAllowance(),
            hasPendingTransaction: hasPendingTransaction,
            isEnoughAmountForExchange: isEnoughAmountForExchange
        )
    }

    func mapToSwappingResultDataModel(
        preview: PreviewSwappingDataModel,
        transaction: ExchangeTransactionDataModel
    ) async throws -> SwappingResultDataModel {
        guard let amount = amount else {
            throw ExchangeManagerError.amountNotFound
        }

        let source = exchangeItems.source
        let sourceBalance = exchangeItems.sourceBalance
        let fee = transaction.fee

        let isEnoughAmountForFee: Bool
        var paymentAmount = amount
        switch exchangeItems.source.currencyType {
        case .coin:
            paymentAmount += fee
            isEnoughAmountForFee = sourceBalance >= fee
        case .token:
            let coinBalance = try await blockchainDataProvider.getBalance(for: source.blockchain)
            isEnoughAmountForFee = coinBalance >= fee
        }

        let isEnoughAmountForExchange = sourceBalance >= paymentAmount

        return SwappingResultDataModel(
            amount: preview.expectedAmount,
            fee: fee,
            isEnoughAmountForExchange: isEnoughAmountForExchange,
            isEnoughAmountForFee: isEnoughAmountForFee,
            isPermissionRequired: !isEnoughAllowance()
        )
    }

    func mapToExchangeTransactionInfo(exchangeData: ExchangeDataModel) throws -> ExchangeTransactionDataModel {
        guard let destination = exchangeItems.destination else {
            throw ExchangeManagerError.destinationNotFound
        }

        return ExchangeTransactionDataModel(
            sourceCurrency: exchangeItems.source,
            sourceBlockchain: exchangeItems.source.blockchain,
            destinationCurrency: destination,
            sourceAddress: exchangeData.sourceAddress,
            destinationAddress: exchangeData.destinationAddress,
            txData: exchangeData.txData,
            amount: exchangeData.swappingAmount,
            value: exchangeData.value,
            gasValue: exchangeData.gas,
            gasPrice: exchangeData.gasPrice
        )
    }

    func mapToExchangeTransactionInfo(
        quoteData: QuoteDataModel,
        approvedData: ExchangeApprovedDataModel
    ) throws -> ExchangeTransactionDataModel {
        guard let destination = exchangeItems.destination else {
            throw ExchangeManagerError.destinationNotFound
        }

        guard let walletAddress = walletAddress else {
            throw ExchangeManagerError.walletAddressNotFound
        }

        return ExchangeTransactionDataModel(
            sourceCurrency: exchangeItems.source,
            sourceBlockchain: exchangeItems.source.blockchain,
            destinationCurrency: destination,
            sourceAddress: walletAddress,
            destinationAddress: approvedData.tokenAddress,
            txData: approvedData.data,
            amount: approvedData.value,
            value: approvedData.value,
            gasValue: quoteData.estimatedGas,
            gasPrice: approvedData.gasPrice
        )
    }
}

extension DefaultExchangeManager {
    enum PendingTransactionState: Hashable {
        case pending(destination: String)
    }
}
