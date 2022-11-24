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
    private weak var delegate: ExchangeManagerDelegate?

    // MARK: - Internal

    private lazy var refreshTxDataTimerPublisher = Timer.publish(every: 10, on: .main, in: .common).autoconnect()

    private var availabilityState: SwappingAvailabilityState = .available
    private var exchangeItems: ExchangeItems
    private var amount: Decimal?
    private var tokenExchangeAllowanceLimit: Decimal?
    private var swappingData: ExchangeSwapDataModel?
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
    }
}

// MARK: - Private

extension DefaultExchangeManager: ExchangeManager {
    func getNetworksAvailableToSwap() -> [String] {
        return [exchangeItems.source.networkId]
    }

    func getExchangeItems() -> ExchangeItems {
        return exchangeItems
    }

    func update(exchangeItems: ExchangeItems) {
        self.exchangeItems = exchangeItems
        if exchangeItems.source.isToken {
            updateExchangeAmountAllowance()
        }

        updateSwappingInformation()
    }

    func isAvailableForExchange(amount: Decimal) -> Bool {
        guard exchangeItems.source.isToken else {
            print("Unnecessary request available for exchange for coin")
            return true
        }

        guard let tokenExchangeAllowanceLimit else {
            assertionFailure("TokenExchangeAllowanceLimit hasn't been updated")
            return false
        }

        return amount <= tokenExchangeAllowanceLimit
    }
    
    func getApprovedDataModel() -> ExchangeApprovedDataModel {
        getExchangeApprovedDataModel()
    }
    
    func approveAndSwapItems() {
        sendTransactionForSwapItems()
    }
    
    func swapItems() {
        sendTransactionForSwapItems()
    }
}

private extension DefaultExchangeManager {
    func updateExchangeAmountAllowance() {
        guard exchangeItems.source.isToken else {
            print("Unnecessary request fetchExchangeAmountAllowance for coin")
            return
        }

        Task {
            do {
                tokenExchangeAllowanceLimit = try await exchangeProvider.fetchExchangeAmountAllowance(for: exchangeItems.source)
            } catch {
                tokenExchangeAllowanceLimit = nil
                availabilityState = .requiredRefresh(occuredError: error)
            }
        }
    }

    func updateSwappingInformation() {
        guard let amount = amount else {
            print("Amount hasn't been set")
            return
        }

        Task {
            do {
                swappingData = try await exchangeProvider.fetchTxDataForSwap(
                    items: exchangeItems,
                    amount: amount.description,
                    slippage: 1 // Default value
                )
            } catch {
                swappingData = nil
                availabilityState = .requiredRefresh(occuredError: error)
            }
        }
    }

    func getExchangeApprovedDataModel() -> ExchangeApprovedDataModel {
        Task {
            do {
                return try await exchangeProvider.approveTxData(for: exchangeItems.source)
            } catch {
                availabilityState = .requiredRefresh(occuredError: error)
            }
        }
    }
    
    func sendTransactionForSwapItems() {
        guard let amount = amount,
              let destination = exchangeItems.destination,
              let swappingData = swappingData,
              let gasPrice = Decimal(string: swappingData.gasPrice) else {
            assertionFailure("Not enough data")
            return
        }
        
        let info = SwapTransactionInfo(
            currency: exchangeItems.source,
            destination: destination.walletAddress,
            amount: amount,
            oneInchTxData: swappingData.txData
        )
        
        let gasValue = Decimal(swappingData.gas)

        Task {
            do {
                try await sendSwapTransaction(info, gasValue: gasValue, gasPrice: gasPrice)
            } catch {
                availabilityState = .requiredRefresh(occuredError: error)
            }
        }
    }
}

private extension DefaultExchangeManager {
    // MARK: - Sending API

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

