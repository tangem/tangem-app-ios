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

    private let swappingItems: ThreadSafeContainer<SwappingItems>
    private var amount: Decimal?
    private var approvePolicy: SwappingApprovePolicy = .unlimited
    private var gasPricePolicy: SwappingGasPricePolicy = .normal
    private let spenderAddresses: ThreadSafeContainer<[SwappingBlockchain: String]> = [:]
    private let swappingAllowanceLimit: ThreadSafeContainer<[Currency: Decimal]> = [:]
    // Cached addresses for check approving transactions
    private let pendingTransactions: ThreadSafeContainer<[Currency: PendingTransactionState]> = [:]
    private var bag: Set<AnyCancellable> = []

    private var formattedAmount: String? {
        guard let amount = amount else {
            logger.debug("[Swap] Amount isn't set")
            return nil
        }

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
        self.swappingItems = .init(swappingItems)
        self.amount = amount

        Task { [weak self] in
            await self?.refreshBalances()
        }
    }
}

// MARK: - SwappingManager

extension CommonSwappingManager: SwappingManager {
    func getAmount() -> Decimal? {
        return amount
    }

    func getSwappingItems() -> SwappingItems {
        return swappingItems.read()
    }

    func getReferrerAccount() -> SwappingReferrerAccount? {
        return referrer
    }

    func getSwappingApprovePolicy() -> SwappingApprovePolicy {
        return approvePolicy
    }

    func getSwappingGasPricePolicy() -> SwappingGasPricePolicy {
        return gasPricePolicy
    }

    func isEnoughAllowance() -> Bool {
        // These local variables are introduced as part of the [REDACTED_INFO] bug investigation;
        // feel free to get rid of them if the bug is fixed
        let sourceItems = swappingItems.source
        let allowanceLimit = swappingAllowanceLimit

        guard
            sourceItems.isToken,
            let amount = amount,
            amount > 0
        else {
            return true
        }

        guard let allowance = allowanceLimit[sourceItems] else {
            return false
        }

        return amount <= allowance
    }

    func update(swappingItems: SwappingItems) {
        self.swappingItems.mutate { $0 = swappingItems }
    }

    func update(amount: Decimal?) {
        self.amount = amount
    }

    func update(approvePolicy: SwappingApprovePolicy) {
        self.approvePolicy = approvePolicy
    }

    func update(gasPricePolicy: SwappingGasPricePolicy) {
        self.gasPricePolicy = gasPricePolicy
    }

    func refreshBalances() async -> SwappingItems {
        try? await updateSwappingItemsBalances()
        return swappingItems.read()
    }

    func refresh(type: SwappingManagerRefreshType) async -> SwappingAvailabilityState {
        return await refreshValues(refreshType: type)
    }

    func didSendApproveTransaction(swappingTxData: SwappingTransactionData) {
        pendingTransactions.mutate { value in
            value[swappingTxData.sourceCurrency] = .pending(destination: swappingTxData.destinationAddress)
        }
        swappingAllowanceLimit.mutate { value in
            value[swappingTxData.sourceCurrency] = nil
        }
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
        let spender = try await getSpenderAddress()
        try await updateSwappingAmountAllowance(spender: spender)

        try Task.checkCancellation()

        // If allowance is enough just load the data for swap this token
        if isEnoughAllowance() {
            // If we saved pending transaction just remove it
            if hasPendingTransaction() {
                pendingTransactions.mutate { [source = swappingItems.source] value in
                    value[source] = nil
                }
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

        let gasOptions = try await getGasOptions(swappingData: swappingData)

        try Task.checkCancellation()

        guard let gas = gasOptions.first(where: { $0.policy == gasPricePolicy }) else {
            throw SwappingManagerError.gasModelNotFound
        }

        let data = try mapToSwappingTransactionData(swappingData: swappingData, gas: gas)
        let availabilityModel = try await mapToSwappingAvailabilityModel(transactionData: data, gasOptions: gasOptions)

        try Task.checkCancellation()

        return .available(availabilityModel)
    }

    func loadApproveData() async throws -> SwappingAvailabilityState {
        // We need to load quoteData for "from" and "to" amounts
        async let quoteData = getSwappingQuoteDataModel()
        async let spender = getSpenderAddress()

        let approvedData = try await getSwappingApprovedDataModel(spender: spender)
        let gasOptions = try await getGasOptions(quoteData: quoteData, approvedData: approvedData)

        try Task.checkCancellation()

        guard let gas = gasOptions.first(where: { $0.policy == gasPricePolicy }) else {
            throw SwappingManagerError.gasModelNotFound
        }

        let data = try await mapToSwappingTransactionData(quoteData: quoteData, approvedData: approvedData, gas: gas)
        let availabilityModel = try await mapToSwappingAvailabilityModel(transactionData: data, gasOptions: gasOptions)

        try Task.checkCancellation()

        return .available(availabilityModel)
    }

    func updateSwappingAmountAllowance(spender: String) async throws {
        let allowance = try await walletDataProvider.getAllowance(for: swappingItems.source, from: spender)
        swappingAllowanceLimit.mutate { [source = swappingItems.source] value in
            value[source] = allowance
        }

        logger.debug("Token \(swappingItems.source.name) allowance \(allowance)")
    }

    func getSwappingQuoteDataModel() async throws -> SwappingQuoteDataModel {
        guard let formattedAmount = formattedAmount else {
            throw SwappingManagerError.amountNotFound
        }

        return try await swappingProvider.fetchQuote(
            items: swappingItems.read(),
            amount: formattedAmount,
            referrer: referrer
        )
    }

    /// Get the sender's address. The router that will provide the exchange
    func getSpenderAddress() async throws -> String {
        let blockchain = swappingItems.source.blockchain

        if let spender = spenderAddresses[blockchain] {
            return spender
        }

        let spender = try await swappingProvider.fetchSpenderAddress(for: blockchain)
        spenderAddresses.mutate { [blockchain] value in
            value[blockchain] = spender
        }

        return spender
    }

    func getSwappingApprovedDataModel(spender: String) throws -> SwappingApprovedDataModel {
        guard let contractAddress = swappingItems.source.contractAddress else {
            throw SwappingManagerError.contractAddressNotFound
        }

        let data = try walletDataProvider.getApproveData(for: swappingItems.source, from: spender, policy: approvePolicy)
        return SwappingApprovedDataModel(data: data, tokenAddress: contractAddress, value: 0)
    }

    func getSwappingTxDataModel() async throws -> SwappingDataModel {
        guard let walletAddress else {
            throw SwappingManagerError.walletAddressNotFound
        }

        guard let formattedAmount = formattedAmount else {
            throw SwappingManagerError.amountNotFound
        }

        return try await swappingProvider.fetchSwappingData(
            items: swappingItems.read(),
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
                swappingItems.mutate { $0.destinationBalance = balance }
            }
        }

        if swappingItems.sourceBalance != balance {
            swappingItems.mutate { $0.sourceBalance = balance }
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

    func mapToSwappingTransactionData(swappingData: SwappingDataModel, gas: EthereumGasDataModel) throws -> SwappingTransactionData {
        guard let destination = swappingItems.destination else {
            throw SwappingManagerError.destinationNotFound
        }

        let value = swappingItems.source.convertFromWEI(value: swappingData.value)

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
            gas: gas
        )
    }

    func mapToSwappingTransactionData(
        quoteData: SwappingQuoteDataModel,
        approvedData: SwappingApprovedDataModel,
        gas: EthereumGasDataModel
    ) throws -> SwappingTransactionData {
        guard let destination = swappingItems.destination else {
            throw SwappingManagerError.destinationNotFound
        }

        guard let walletAddress = walletAddress else {
            throw SwappingManagerError.walletAddressNotFound
        }

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
            gas: gas
        )
    }

    func mapToSwappingAvailabilityModel(
        transactionData: SwappingTransactionData,
        gasOptions: [EthereumGasDataModel]
    ) async throws -> SwappingAvailabilityModel {
        let amount = transactionData.sourceCurrency.convertFromWEI(value: transactionData.sourceAmount)
        let sourceBalance = swappingItems.sourceBalance
        let coinBalance = try await walletDataProvider.getBalance(for: swappingItems.source.blockchain)

        var isEnoughAmountForFee: [SwappingGasPricePolicy: Bool] = [:]
        var isEnoughAmountForSwapping: [SwappingGasPricePolicy: Bool] = [:]

        for option in gasOptions {
            switch swappingItems.source.currencyType {
            case .coin:
                isEnoughAmountForFee[option.policy] = sourceBalance >= option.fee
                isEnoughAmountForSwapping[option.policy] = sourceBalance >= amount + option.fee
            case .token:
                isEnoughAmountForFee[option.policy] = coinBalance >= option.fee
                isEnoughAmountForSwapping[option.policy] = sourceBalance >= amount
            }
        }

        let restrictions = SwappingAvailabilityModel.Restrictions(
            isEnoughAmountForSwapping: isEnoughAmountForSwapping,
            isEnoughAmountForFee: isEnoughAmountForFee,
            isPermissionRequired: !isEnoughAllowance()
        )

        return SwappingAvailabilityModel(
            transactionData: transactionData,
            gasOptions: gasOptions,
            restrictions: restrictions
        )
    }
}

// MARK: - Fee calculation

private extension CommonSwappingManager {
    func getGasOptions(swappingData: SwappingDataModel) async throws -> [EthereumGasDataModel] {
        let value = swappingItems.source.convertFromWEI(value: swappingData.value)
        return try await walletDataProvider.getGasOptions(
            blockchain: swappingItems.source.blockchain,
            value: value,
            data: swappingData.txData,
            destinationAddress: swappingData.destinationAddress
        )
    }

    func getGasOptions(
        quoteData: SwappingQuoteDataModel,
        approvedData: SwappingApprovedDataModel
    ) async throws -> [EthereumGasDataModel] {
        let value = swappingItems.source.convertFromWEI(value: approvedData.value)
        return try await walletDataProvider.getGasOptions(
            blockchain: swappingItems.source.blockchain,
            value: value,
            data: approvedData.data,
            destinationAddress: approvedData.tokenAddress
        )
    }
}

extension CommonSwappingManager {
    enum PendingTransactionState: Hashable {
        case pending(destination: String)
    }
}
