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
    private let signTypedDataProvider: SignTypedDataProviding

    // MARK: - Internal

    private var availabilityState: ExchangeAvailabilityState = .idle {
        didSet { delegate?.exchangeManager(self, didUpdate: availabilityState) }
    }
    private var exchangeItems: ExchangeItems {
        didSet { delegate?.exchangeManager(self, didUpdate: exchangeItems) }
    }
    private var tokenExchangeAllowanceLimit: Decimal? {
        didSet { delegate?.exchangeManager(self, didUpdate: isEnoughAllowance()) }
    }

    private weak var delegate: ExchangeManagerDelegate?
    private var amount: Decimal?
    private lazy var refreshDataTimer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()
    private var refreshDataTimerBag: AnyCancellable?

    private var walletAddress: String? {
        blockchainDataProvider.getWalletAddress(currency: exchangeItems.source)
    }

    init(
        exchangeProvider: ExchangeProvider,
        blockchainInfoProvider: BlockchainDataProvider,
        signTypedDataProvider: SignTypedDataProviding,
        exchangeItems: ExchangeItems,
        amount: Decimal? = nil
    ) {
        self.exchangeProvider = exchangeProvider
        self.blockchainDataProvider = blockchainInfoProvider
        self.signTypedDataProvider = signTypedDataProvider
        self.exchangeItems = exchangeItems
        self.amount = amount

        updateSourceBalances()
        Task {
            await updateExchangeAmountAllowance()
        }
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

    func updatePermit() {
        Task {
            do {
                exchangeItems.permit = try await getPermitSignature(spenderAddress: getSpenderAddress())
                refreshValues(silent: false)
            } catch {
                updateState(.requiredRefresh(occurredError: ExchangeManagerError.permitCannotCreated))
            }
        }
    }

    func refresh() {
        tokenExchangeAllowanceLimit = nil
        refreshValues(silent: false)
    }
}

// MARK: - Fields Changes

private extension DefaultExchangeManager {
    func amountDidChange() {
        updateSourceBalances()

        if amount == nil || amount == 0 {
            stopTimer()
            updateState(.idle)
            return
        }

        restartTimer()
        refreshValues(silent: false)
    }

    func exchangeItemsDidChange() {
        /// Set nil for previous token
        tokenExchangeAllowanceLimit = nil
        updateSourceBalances()

        guard (amount ?? 0) > 0 else {
            stopTimer()
            return
        }

        restartTimer()
        refreshValues(silent: false)
    }
}

// MARK: - State updates

private extension DefaultExchangeManager {
    func updateState(_ state: ExchangeAvailabilityState) {
        self.availabilityState = state
    }

    func restartTimer() {
        stopTimer()
        startTimer()
    }

    func startTimer() {
        refreshDataTimerBag = refreshDataTimer
            .upstream
            .sink { [weak self] _ in
                self?.refreshValues(silent: true)
            }
    }

    func stopTimer() {
        refreshDataTimerBag?.cancel()
        refreshDataTimer
            .upstream
            .connect()
            .cancel()
    }
}

// MARK: - Requests

private extension DefaultExchangeManager {
    func refreshValues(silent: Bool) {
        if !silent {
            updateState(.loading)
        }

        Task {
            do {
                let quoteData = try await getQuoteDataModel()
                let preview = try await mapPreviewSwappingDataModel(from: quoteData)

                switch exchangeItems.source.currencyType {
                case .coin:
                    try await refreshValuesViaSwapping(preview: preview, permit: nil)
                case .token:
                    if exchangeItems.supportedPermit {
                        if let permit = exchangeItems.permit {
                            try await refreshValuesViaSwapping(preview: preview, permit: permit)
                        } else {
                            updateState(.preview(preview))
                        }
                    } else {
                        try await refreshValuesViaApprove(quoteData: quoteData, preview: preview)
                    }
                }
            } catch {
                updateState(.requiredRefresh(occurredError: error))
            }
        }
    }

    func refreshValuesViaSwapping(preview: PreviewSwappingDataModel, permit: String?) async throws {
        guard preview.isEnoughAmountForExchange else {
            updateState(.preview(preview))
            return
        }

        let exchangeData = try await getExchangeTxDataModel(permit: permit)
        let info = try mapToExchangeTransactionInfo(exchangeData: exchangeData)
        let result = try await mapToSwappingResultDataModel(preview: preview, transaction: info)
        updateState(.available(result, info: info))
    }

    func refreshValuesViaApprove(quoteData: QuoteDataModel, preview: PreviewSwappingDataModel) async throws {
        await updateExchangeAmountAllowance()

        let approvedDataModel = try await getExchangeApprovedDataModel()
        let info = try mapToExchangeTransactionInfo(
            quoteData: quoteData,
            approvedData: approvedDataModel
        )
        let result = try await mapToSwappingResultDataModel(preview: preview, transaction: info)
        updateState(.available(result, info: info))
    }

    func updateExchangeAmountAllowance() async {
        /// If allowance limit already loaded use it
        guard tokenExchangeAllowanceLimit == nil,
              let walletAddress else {
            delegate?.exchangeManager(self, didUpdate: isEnoughAllowance())
            return
        }

        do {
            tokenExchangeAllowanceLimit = try await exchangeProvider.fetchAmountAllowance(
                for: exchangeItems.source,
                walletAddress: walletAddress
            )
        } catch {
            tokenExchangeAllowanceLimit = nil
            updateState(.requiredRefresh(occurredError: error))
        }
    }

    func getQuoteDataModel() async throws -> QuoteDataModel {
        try await exchangeProvider.fetchQuote(
            items: exchangeItems,
            amount: formattedAmount()
        )
    }

    func getExchangeApprovedDataModel() async throws -> ExchangeApprovedDataModel {
        try await exchangeProvider.fetchApproveExchangeData(for: exchangeItems.source)
    }

    func getSpenderAddress() async throws -> String {
        try await exchangeProvider.fetchSpenderAddress(for: exchangeItems.source)
    }

    func getExchangeTxDataModel(permit: String?) async throws -> ExchangeDataModel {
        guard let walletAddress else {
            throw ExchangeManagerError.walletAddressNotFound
        }

        print("Permit", permit as Any)

        return try await exchangeProvider.fetchExchangeData(
            items: exchangeItems,
            walletAddress: walletAddress,
            amount: formattedAmount(),
            permit: permit
        )
    }

    /*
     0x
     d380261114f7c3006efa1b0dfb952f1f098c23c9394d6778406e1c2d420896dd
     200a15c97037342a883d74999156ede0d3ee40c25624e21ccb8a38bca7433aaf
     1c
     */

    func updateSourceBalances() {
        Task {
            let source = exchangeItems.source
            let balance = try await blockchainDataProvider.getBalance(for: source)
            var fiatBalance: Decimal = 0
            if let amount = amount {
                fiatBalance = try await blockchainDataProvider.getFiat(for: source, amount: amount)
            }

            exchangeItems.sourceBalance = ExchangeItems.Balance(balance: balance, fiatBalance: fiatBalance)
        }
    }

    func getPermitSignature(spenderAddress: String) async throws -> String {
        guard let amount = amount else {
            throw ExchangeManagerError.amountNotFound
        }

        guard let walletAddress = walletAddress else {
            throw ExchangeManagerError.walletAddressNotFound
        }

        let dataModel = SignTypedDataPermitDataModel(
            walletAddress: walletAddress,
            spenderAddress: spenderAddress,
            amount: amount
        )

        let permit = try await signTypedDataProvider.permitData(
            for: exchangeItems.source,
            dataModel: dataModel,
            deadline: Date(timeIntervalSinceNow: 60 * 30)
        )

        return permit.lowercased()
    }

    private func formattedAmount() -> String {
        guard let amount else {
            assertionFailure("Amount not set")
            return ""
        }

        return String(describing: exchangeItems.source.convertToWEI(value: amount))
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
        let expectedFiatAmount = try await blockchainDataProvider.getFiat(for: destination, amount: expectedAmount)

        let isEnoughAmountForExchange = exchangeItems.sourceBalance.balance >= paymentAmount

        return PreviewSwappingDataModel(
            expectedAmount: expectedAmount,
            expectedFiatAmount: expectedFiatAmount,
            isPermissionRequired: !isEnoughAllowance(),
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
        let sourceBalance = exchangeItems.sourceBalance.balance
        let fee = transaction.fee

        let fiatFee = try await blockchainDataProvider.getFiat(for: source.blockchain, amount: transaction.fee)

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
            fiatAmount: preview.expectedFiatAmount,
            fee: fee,
            fiatFee: fiatFee,
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
            amount: exchangeData.sourceTokenAmount,
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
            gasValue: quoteData.estimatedGas,
            gasPrice: approvedData.gasPrice
        )
    }
}
