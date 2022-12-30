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
    private let permitTypedDataProvider: PermitTypedDataProviding

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
        permitTypedDataProvider: PermitTypedDataProviding,
        exchangeItems: ExchangeItems,
        amount: Decimal? = nil
    ) {
        self.exchangeProvider = exchangeProvider
        self.blockchainDataProvider = blockchainInfoProvider
        self.permitTypedDataProvider = permitTypedDataProvider
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
        exchangeItems.permit = nil
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
        exchangeItems.permit = nil
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

        return try await exchangeProvider.fetchExchangeData(
            items: exchangeItems,
            walletAddress: walletAddress,
            amount: formattedAmount(),
            permit: permit
        )
    }

    /*
     URL: https://api-tangem.1inch.io/v5.0/56/swap?amount=1000000000000000000&fromAddress=0x29010F8F91B980858EB298A0843264cfF21Fd9c9&fromTokenAddress=0x111111111117dc0aa78b770fa6a738034120c302&permit=
     0x
     00000000000000000000000029010f8f91b980858eb298a0843264cff21fd9c9
     0000000000000000000000001111111254eeb25477b68fb85ed929f73a960582
     0000000000000000000000000000000000c097ce7bc90715b34b9f1000000000
     000000000000000000000000000000000000000000000000000001855e59b424
     000000000000000000000000000000000000000000000000000000000000001b
     1f837357e7eca96e8d3d1aaeaffa0d32c991025bf5028569f903f5f6342d9735
     5fcf8086f31f4d8cb3efa751b6cc6ada64f1b9aee762c5951c4741ce888af389
     &slippage=1&toTokenAddress=0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
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

        let parameters = PermitParameters(
            walletAddress: walletAddress,
            spenderAddress: spenderAddress,
            amount: exchangeItems.source.convertToWEI(value: amount),
            deadline: Date(timeIntervalSinceNow: 60 * 30) // 30 min
        )

        let permitCallData = try await permitTypedDataProvider.buildPermitCallData(for: exchangeItems.source, parameters: parameters)
        print("permitCallData \n \(permitCallData)")
        return permitCallData.lowercased()
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
