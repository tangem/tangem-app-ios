//
//  DefaultExchangeManager.swift
//  TangemExchange
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class DefaultExchangeManager<TxBuilder: TransactionBuilder> {
    // MARK: - Dependencies

    private let exchangeProvider: ExchangeProvider
    private let transactionBuilder: TxBuilder
    private let blockchainInfoProvider: BlockchainInfoProvider

    // MARK: - Internal

    private lazy var refreshDataTimer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()

    private var availabilityState: ExchangeAvailabilityState = .idle {
        didSet { delegate?.exchangeManager(self, didUpdate: availabilityState) }
    }
    private var exchangeItems: ExchangeItems {
        didSet { delegate?.exchangeManager(self, didUpdate: exchangeItems) }
    }
    private var tokenExchangeAllowanceLimit: Decimal? {
        didSet {
            delegate?.exchangeManager(self, didUpdate: isAvailableForExchange())
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

    private var walletAddress: String? {
        blockchainInfoProvider.getWalletAddress(currency: exchangeItems.source)
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

    func getNetworksAvailableToExchange() -> [String] {
        [exchangeItems.source.blockchain.networkId]
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
        exchangeItemsDidChange()
    }

    func update(amount: Decimal?) {
        self.amount = amount
        amountDidChange()
    }

    func refresh() {
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

// MARK: - Request

private extension DefaultExchangeManager {
    func refreshValues(silent: Bool) {
        if !silent {
            updateState(.loading)
        }

        Task {
            do {
                let result = try await getExpectSwappingResult()

                switch exchangeItems.source.currencyType {
                case .coin:
                    if result.isEnoughAmountForExchange {
                        let txData = try await getExchangeTxDataModel()
                        updateState(.available(expect: result, txData: txData))
                    } else {
                        updateState(.preview(expect: result))
                    }
                case .token:
                    await updateExchangeAmountAllowance()
                    let approvedDataModel = try await getExchangeApprovedDataModel()
                    updateState(
                        .requiredPermission(expect: result, approvedDataModel: approvedDataModel)
                    )
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

    func getExpectSwappingResult() async throws -> ExpectSwappingResult {
        let quoteData = try await exchangeProvider.fetchQuote(
            items: exchangeItems,
            amount: formattedAmount
        )

        return try mapExpectSwappingResult(from: quoteData)
    }

    func getExchangeApprovedDataModel() async throws -> ExchangeApprovedDataModel {
        return try await exchangeProvider.fetchApproveExchangeData(for: exchangeItems.source)
    }

    func getExchangeTxDataModel() async throws -> ExchangeDataModel {
        guard let walletAddress else {
            print("walletAddress not found")
            throw ExchangeManagerErrors.walletAddressNotFound
        }

        return try await exchangeProvider.fetchExchangeData(
            items: exchangeItems,
            walletAddress: walletAddress,
            amount: formattedAmount
        )
    }

    func updateSourceBalances() {
        let source = exchangeItems.source
        let balance = blockchainInfoProvider.getBalance(currency: source)
        var fiatBalance: Decimal = 0
        if let amount = amount {
            fiatBalance = blockchainInfoProvider.getFiatBalance(currency: source, amount: amount)
        }

        exchangeItems.sourceBalance = ExchangeItems.Balance(balance: balance, fiatBalance: fiatBalance)
    }
}

// MARK: - Mapping

private extension DefaultExchangeManager {
    func mapExpectSwappingResult(from quoteData: QuoteData) throws -> ExpectSwappingResult {
        guard let expectAmount = Decimal(string: quoteData.toTokenAmount),
              let amount else {
            throw ExchangeManagerErrors.incorrectData
        }

        let decimalNumber = exchangeItems.destination.decimalCount.asLongNumber.decimal
        let expectFiatAmount = blockchainInfoProvider.getFiatBalance(
            currency: exchangeItems.destination,
            amount: expectAmount / decimalNumber
        )

        let fee = Decimal(integerLiteral: quoteData.estimatedGas)
        let fiatFee = blockchainInfoProvider.getFiatBalance(
            currency: exchangeItems.destination,
            amount: fee / decimalNumber
        )

        let isEnoughAmountForExchange = exchangeItems.sourceBalance.balance > amount

        return ExpectSwappingResult(
            expectAmount: expectAmount / decimalNumber,
            expectFiatAmount: expectFiatAmount,
            fee: fee / decimalNumber,
            fiatFee: fiatFee,
            decimalCount: quoteData.toToken.decimals,
            isEnoughAmountForExchange: isEnoughAmountForExchange
        )
    }
}

// MARK: - Sending API

private extension DefaultExchangeManager {
    func sendExchangeTransaction(_ info: ExchangeTransactionInfo, gasValue: Decimal, gasPrice: Decimal) async throws {
        let gas = gas(from: gasValue, price: gasPrice, decimalCount: info.currency.decimalCount)

        let transaction = try transactionBuilder.buildTransaction(for: info, fee: gas)
        let signedTransaction = try await transactionBuilder.sign(transaction)

        return try await transactionBuilder.send(signedTransaction)
    }

    func submitPermissionForToken(_ info: ExchangeTransactionInfo, gasPrice: Decimal) async throws {
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
