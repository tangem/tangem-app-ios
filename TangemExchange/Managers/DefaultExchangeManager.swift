//
//  DefaultExchangeManager.swift
//  TangemExchange
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

enum ExchangeManagerErrors: Error {
    case notCorrectData
}

class DefaultExchangeManager<TxBuilder: TransactionBuilder> {
    // MARK: - Dependencies

    private let exchangeProvider: ExchangeProvider
    private let transactionBuilder: TxBuilder
    private let blockchainInfoProvider: BlockchainInfoProvider

    // MARK: - Internal

    private lazy var refreshDataTimer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()

    private var availabilityState: SwappingAvailabilityState = .idle {
        didSet { delegate?.exchangeManagerDidUpdate(availabilityState: availabilityState) }
    }
    private var exchangeItems: ExchangeItems {
        didSet { delegate?.exchangeManagerDidUpdate(exchangeItems: exchangeItems) }
    }
    private var tokenExchangeAllowanceLimit: Decimal? {
        didSet {
            delegate?.exchangeManagerDidUpdate(
                availabilityForExchange: isAvailableForExchange(),
                limit: tokenExchangeAllowanceLimit
            )
        }
    }

    private weak var delegate: ExchangeManagerDelegate?
    private var amount: Decimal?
    private var formattedAmount: String {
        guard var amount else {
            assertionFailure("Amount not set")
            return ""
        }

        amount *= exchangeItems.source.decimalCount.asLongNumber.decimal
        return String(describing: amount)
    }
    private var refreshDataTimerBag: AnyCancellable?
    private var bag: Set<AnyCancellable> = []

    init(
        exchangeProvider: ExchangeProvider,
        transactionBuilder: TxBuilder,
        blockchainInfoProvider: BlockchainInfoProvider,
        exchangeItems: ExchangeItems,
        amount: Decimal? = nil
    ) {
        self.exchangeProvider = exchangeProvider
        self.transactionBuilder = transactionBuilder
        self.blockchainInfoProvider = blockchainInfoProvider
        self.exchangeItems = exchangeItems
        self.amount = amount

        updateSourceBalances()
        updateExchangeAmountAllowance()
    }
}

// MARK: - ExchangeManager

extension DefaultExchangeManager: ExchangeManager {
    func setDelegate(_ delegate: ExchangeManagerDelegate) {
        self.delegate = delegate
    }

    func getNetworksAvailableToSwap() -> [String] {
        return [exchangeItems.source.blockchain.id]
    }

    func getAvailabilityState() -> SwappingAvailabilityState {
        return availabilityState
    }

    func getExchangeItems() -> ExchangeItems {
        return exchangeItems
    }

    func isAvailableForExchange() -> Bool {
        guard exchangeItems.source.isToken else {
            print("Unnecessary request available for exchange for coin")
            return true
        }

        /// If we don't have values, `return true` for move view to default state
        guard let tokenExchangeAllowanceLimit, let amount else {
            return true
        }

        return amount <= tokenExchangeAllowanceLimit
    }

    func update(exchangeItems: ExchangeItems) {
        self.exchangeItems = exchangeItems
        exchangeItemsDidUpdate()
    }

    func update(amount: Decimal?) {
        self.amount = amount
        amountDidChange()
    }

    func approveAndSwapItems() {
//        sendTransactionForSwapItems()
    }

    func swapItems() {
//        sendTransactionForSwapItems()
    }
}

// MARK: - Fields Changes

private extension DefaultExchangeManager {
    func amountDidChange() {
        updateSourceBalances()

        if amount == nil {
            updateState(.idle)
            return
        }

        updateExpectSwappingResult()

        guard let tokenExchangeAllowanceLimit else {
            return
        }

        delegate?.exchangeManagerDidUpdate(
            availabilityForExchange: isAvailableForExchange(),
            limit: tokenExchangeAllowanceLimit
        )
    }

    func exchangeItemsDidUpdate() {
        if exchangeItems.source.isToken {
            updateExchangeAmountAllowance()
        }

        restartTimer()
        updateExpectSwappingResult()
    }
}

// MARK: - State updates

private extension DefaultExchangeManager {
    func updateState(_ state: SwappingAvailabilityState) {
        self.availabilityState = state
    }

    func restartTimer() {
        stopTimer()
        startTimer()
    }

    func startTimer() {
        refreshDataTimerBag = refreshDataTimer
            .print("timer")
            .upstream
            .print("timer upstream")
            .sink { [weak self] _ in
                self?.updateExpectSwappingResult()
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

// MARK: - Request

private extension DefaultExchangeManager {
    func updateExchangeAmountAllowance() {
        guard exchangeItems.source.isToken else {
            print("Unnecessary request fetchExchangeAmountAllowance for coin")
            return
        }

        guard let walletAddress = blockchainInfoProvider.getWalletAddress(currency: exchangeItems.source) else {
            print("walletAddress not found")
            return
        }

        Task {
            do {
                tokenExchangeAllowanceLimit = try await exchangeProvider.fetchExchangeAmountAllowance(
                    for: exchangeItems.source,
                    walletAddress: walletAddress
                )
            } catch {
                tokenExchangeAllowanceLimit = nil
                updateState(.requiredRefresh(occurredError: error))
            }
        }
    }

    func updateExpectSwappingResult() {
        guard (amount ?? 0) > 0 else { return }

        updateState(.loading)

        Task {
            do {
                let quoteData = try await exchangeProvider.fetchQuote(
                    items: exchangeItems,
                    amount: formattedAmount
                )

                let swappingResult = try mapExpectSwappingResult(from: quoteData)
                updateState(.requiredPermission(swappingResult: swappingResult))

            } catch {
                updateState(.requiredRefresh(occurredError: error))
            }
        }
    }

    func updateSourceBalances() {
        let source = exchangeItems.source
        let balance = blockchainInfoProvider.getBalance(currency: source)
        var fiatBalance: Decimal = 0
        if let amount {
            fiatBalance = blockchainInfoProvider.getFiatBalance(currency: source, amount: amount)
        }

        exchangeItems.sourceBalance = CurrencyBalance(balance: balance, fiatBalance: fiatBalance)
    }
}

// MARK: - Mapping

private extension DefaultExchangeManager {
    func mapExpectSwappingResult(from quoteData: QuoteData) throws -> ExpectSwappingResult {
        guard let expectAmount = Decimal(string: quoteData.toTokenAmount) else {
            throw ExchangeManagerErrors.notCorrectData
        }

        let decimalNumber = exchangeItems.destination.decimalCount.asLongNumber.decimal
        let expectFiatAmount = blockchainInfoProvider.getFiatBalance(
            currency: exchangeItems.destination,
            amount: expectAmount / decimalNumber
        )

        let fee = Decimal(integerLiteral: quoteData.estimatedGas)
        return ExpectSwappingResult(
            expectAmount: expectAmount / decimalNumber,
            expectFiatAmount: expectFiatAmount,
            fee: fee / decimalNumber,
            decimalCount: quoteData.toToken.decimals
        )
    }
}

// MARK: - Sending API

private extension DefaultExchangeManager {

    func sendSwapTransaction(_ info: SwapTransactionInfo, gasValue: Decimal, gasPrice: Decimal) async throws {
        let gas = gas(from: gasValue, price: gasPrice, decimalCount: info.currency.decimalCount)

        let transaction = try transactionBuilder.buildTransaction(for: info, fee: gas)
        let signedTransaction = try await transactionBuilder.sign(transaction)

        return try await transactionBuilder.send(signedTransaction)
    }

    func submitPermissionForToken(_ info: SwapTransactionInfo, gasPrice: Decimal) async throws {
        let fees = try await blockchainInfoProvider.getFee(currency: info.currency, amount: info.amount, destination: info.destination)
        let gasValue: Decimal = fees[1]

        let gas = gas(from: gasValue, price: gasPrice, decimalCount: info.currency.decimalCount)
        let transaction = try transactionBuilder.buildTransaction(for: info, fee: gas)
        let signedTransaction = try await transactionBuilder.sign(transaction)

        return try await transactionBuilder.send(signedTransaction)
    }

    func gas(from value: Decimal, price: Decimal, decimalCount: Int) -> Decimal {
        value * price / Decimal(decimalCount)
    }
}

private extension Int {
    var asLongNumber: Int {
        (0 ..< self).reduce(1) { number, _ in number * 10 }
    }

    var decimal: Decimal {
        Decimal(integerLiteral: self)
    }
}
