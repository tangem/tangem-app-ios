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

    // MARK: - Internal

    private lazy var refreshDataTimer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    private var availabilityState: ExchangeAvailabilityState = .idle {
        didSet { delegate?.exchangeManager(self, didUpdate: availabilityState) }
    }
    private var exchangeItems: ExchangeItems {
        didSet { delegate?.exchangeManager(self, didUpdate: exchangeItems) }
    }
    private var tokenExchangeAllowanceLimit: Decimal? {
        didSet {
            print("tokenExchangeAllowanceLimit", tokenExchangeAllowanceLimit)
            delegate?.exchangeManager(self, didUpdate: isAvailableForExchange())
        }
    }

    private weak var delegate: ExchangeManagerDelegate?
    private var amount: Decimal?
    private var formattedAmount: String {
        guard let amount else {
            assertionFailure("Amount not set")
            return ""
        }

        return String(describing: exchangeItems.source.multiply(value: amount))
    }

    private var walletAddress: String? {
        blockchainDataProvider.getWalletAddress(currency: exchangeItems.source)
    }

    private var refreshDataTimerBag: AnyCancellable?
    private var bag: Set<AnyCancellable> = []

    init(
        exchangeProvider: ExchangeProvider,
        blockchainInfoProvider: BlockchainDataProvider,
        exchangeItems: ExchangeItems,
        amount: Decimal? = nil
    ) {
        self.exchangeProvider = exchangeProvider
        self.blockchainDataProvider = blockchainInfoProvider
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

    func isAvailableForExchange() -> Bool {
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

    func refresh() {
        tokenExchangeAllowanceLimit = nil
        refreshValues(silent: true)
    }
}

// MARK: - Fields Changes

private extension DefaultExchangeManager {
    func amountDidChange() {
        updateSourceBalances()

        if amount == nil || amount == 0 {
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

        guard (amount ?? 0) > 0 else { return }

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
                let result = try await mapExpectedSwappingResult(from: quoteData)

                guard result.isEnoughAmountForExchange else {
                    updateState(.preview(expected: result))
                    return
                }

                switch exchangeItems.source.currencyType {
                case .coin:
                    let exchangeData = try await getExchangeTxDataModel()
                    let info = try mapToExchangeTransactionInfo(exchangeData: exchangeData)
                    updateState(.available(expected: result, info: info))
                case .token:
                    await updateExchangeAmountAllowance()

                    let approvedDataModel = try await getExchangeApprovedDataModel()
                    let spender = try await getApprovedSpenderAddress()
                    let info = try mapToExchangeTransactionInfo(
                        quoteData: quoteData,
                        approvedData: approvedDataModel,
                        spenderAddress: spender
                    )
                    updateState(.requiredPermission(expected: result, info: info))
                }
            } catch {
                updateState(.requiredRefresh(occurredError: error))
            }
        }
    }

    func updateExchangeAmountAllowance() async {
        /// If allowance limit already loaded use it
        guard tokenExchangeAllowanceLimit == nil,
              let walletAddress else {
            delegate?.exchangeManager(self, didUpdate: isAvailableForExchange())
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
            amount: formattedAmount
        )
    }

    func getExchangeApprovedDataModel() async throws -> ExchangeApprovedDataModel {
        return try await exchangeProvider.fetchApproveExchangeData(for: exchangeItems.source)
    }

    func getApprovedSpenderAddress() async throws -> String {
        return try await exchangeProvider.fetchSpenderAddress(for: exchangeItems.source)
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

    func updateSourceBalances() {
        Task {
            let source = exchangeItems.source
            let balance = try await blockchainDataProvider.getBalance(currency: source)
            var fiatBalance: Decimal = 0
            if let amount = amount  {
                fiatBalance = try await blockchainDataProvider.getFiatBalance(currency: source, amount: amount)
            }

            exchangeItems.sourceBalance = ExchangeItems.Balance(balance: balance, fiatBalance: fiatBalance)
        }
    }
}

// MARK: - Mapping

private extension DefaultExchangeManager {
    func mapExpectedSwappingResult(from quoteData: QuoteDataModel) async throws -> ExpectedSwappingResult {
        guard let destination = exchangeItems.destination else {
            throw ExchangeManagerError.destinationNotFound
        }

        let paymentAmount = exchangeItems.source.divide(value: quoteData.fromTokenAmount)
        let expectedAmount = destination.divide(value: quoteData.toTokenAmount)

        let expectedFiatAmount = try await blockchainDataProvider.getFiatBalance(
            currency: destination,
            amount: expectedAmount
        )

        let feeFiatRate = try await blockchainDataProvider.getFiatRateForFee(currency: destination)

        let isEnoughAmountForExchange = exchangeItems.sourceBalance.balance >= paymentAmount

        return ExpectedSwappingResult(
            expectedAmount: expectedAmount,
            expectedFiatAmount: expectedFiatAmount,
            feeFiatRate: feeFiatRate,
            decimalCount: exchangeItems.source.decimalCount,
            isEnoughAmountForExchange: isEnoughAmountForExchange
        )
    }

    func mapToExchangeTransactionInfo(exchangeData: ExchangeDataModel) throws -> ExchangeTransactionDataModel {
        guard let destination = exchangeItems.destination else {
            throw ExchangeManagerError.destinationNotFound
        }

        return ExchangeTransactionDataModel(
            sourceCurrency: exchangeItems.source,
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
        approvedData: ExchangeApprovedDataModel,
        spenderAddress: String
    ) throws -> ExchangeTransactionDataModel {
        guard let destination = exchangeItems.destination else {
            throw ExchangeManagerError.destinationNotFound
        }

        guard let walletAddress = walletAddress else {
            throw ExchangeManagerError.walletAddressNotFound
        }

        return ExchangeTransactionDataModel(
            sourceCurrency: exchangeItems.source,
            destinationCurrency: destination,
            sourceAddress: walletAddress,
            destinationAddress: spenderAddress,
            txData: approvedData.data,
            amount: approvedData.value,
            gasValue: quoteData.estimatedGas,
            gasPrice: approvedData.gasPrice
        )
    }
}
