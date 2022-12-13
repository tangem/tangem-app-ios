//
//  TransactionSender.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import TangemExchange
import BlockchainSdk

struct TransactionSender {
    private let walletModel: WalletModel
    private let signer: TransactionSigner
    private let currencyMapper: CurrencyMapping

    private var walletManager: WalletManager { walletModel.walletManager }

    init(
        walletModel: WalletModel,
        signer: TransactionSigner,
        currencyMapper: CurrencyMapping
    ) {
        self.walletModel = walletModel
        self.signer = signer
        self.currencyMapper = currencyMapper
    }
}

// MARK: - TransactionSenderProtocol

extension TransactionSender: TransactionSenderProtocol {
    func sendExchangeTransaction(_ info: ExchangeTransactionInfo, gasValue: Decimal, gasPrice: Decimal) async throws {
        let gas = gas(from: gasValue, price: gasPrice, decimalCount: info.currency.decimalCount)

        let transaction = try buildTransaction(for: info, fee: gas)

        return try await send(transaction)
    }

    func sendPermissionTransaction(_ info: ExchangeTransactionInfo, gasPrice: Decimal) async throws {
        let fees = try await getFee(currency: info.currency, amount: info.amount, destination: info.destination)
        let gasValue: Decimal = fees[1]

        let gas = gas(from: gasValue, price: gasPrice, decimalCount: info.currency.decimalCount)
        let transaction = try buildTransaction(for: info, fee: info.fee)

        return try await send(transaction)
    }
}

// MARK: - Private

private extension TransactionSender {
    func buildTransaction(for info: ExchangeTransactionInfo, fee: Decimal) throws -> Transaction {
        let amount = createAmount(from: info.currency, amount: info.amount)
        let fee = createAmount(from: info.currency, amount: fee)

        var transaction = try walletManager.createTransaction(
            amount: amount,
            fee: fee,
            destinationAddress: info.destination,
            sourceAddress: info.source,
            changeAddress: nil // For what?
        )

        transaction.params = EthereumTransactionParams(data: info.oneInchTxData)

        print("transaction", transaction)


        return transaction
    }

    func send(_ transaction: Transaction) async throws {
        try await walletManager.send(transaction, signer: signer).async()
    }

    func getFee(currency: Currency, amount: Decimal, destination: String) async throws -> [Decimal] {
        let amount = createAmount(from: currency, amount: amount)

        let fees = try await walletManager.getFee(amount: amount, destination: destination).async()
        return fees.map { $0.value }
    }

    func gas(from value: Decimal, price: Decimal, decimalCount: Int) -> Decimal {
        let decimalValue = pow(10, decimalCount)
        return value * price / decimalValue
    }

    func createAmount(from currency: Currency, amount: Decimal) -> Amount {
        if let token = currencyMapper.mapToToken(currency: currency) {
            return Amount(with: token, value: amount)
        }

        return Amount(
            type: .coin,
            currencySymbol: currency.symbol,
            value: amount,
            decimals: currency.decimalCount
        )
    }
}
