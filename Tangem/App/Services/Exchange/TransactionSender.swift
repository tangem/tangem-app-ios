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
    func sendExchangeTransaction(_ info: ExchangeTransactionDataModel) async throws {
        let transaction = try buildTransaction(for: info)
        return try await send(transaction)
    }

    func sendPermissionTransaction(_ info: ExchangeTransactionDataModel) async throws {
        let transaction = try buildTransaction(for: info)
        return try await send(transaction)
    }
}

// MARK: - Private

private extension TransactionSender {
    func buildTransaction(for info: ExchangeTransactionDataModel) throws -> Transaction {
        let amount = createAmount(from: info.sourceCurrency, amount: info.amount / info.sourceCurrency.decimalValue)
        let fee = try createAmount(from: info.destinationCurrency.blockchain, amount: info.fee)

        var transaction = try walletManager.createTransaction(
            amount: amount,
            fee: fee,
            destinationAddress: info.destinationAddress,
            sourceAddress: info.sourceAddress
        )

        transaction.params = EthereumTransactionParams(data: info.txData, gasLimit: info.gasValue)

        print("transaction", transaction)

        return transaction
    }

    func send(_ transaction: Transaction) async throws {
        try await walletManager.send(transaction, signer: signer).async()
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

    func createAmount(from exchangeBlockchain: ExchangeBlockchain, amount: Decimal) throws -> Amount {
        guard let blockchain = Blockchain(from: exchangeBlockchain.networkId) else {
            throw CommonError.noData
        }

        return Amount(with: blockchain, value: amount)
    }
}
