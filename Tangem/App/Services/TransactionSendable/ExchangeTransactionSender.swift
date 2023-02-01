//
//  ExchangeTransactionSender.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import TangemExchange
import BlockchainSdk

struct ExchangeTransactionSender {
    private let transactionCreator: TransactionCreator
    private let transactionSender: TransactionSender
    private let transactionSigner: TransactionSigner
    private let currencyMapper: CurrencyMapping

    init(
        transactionCreator: TransactionCreator,
        transactionSender: TransactionSender,
        transactionSigner: TransactionSigner,
        currencyMapper: CurrencyMapping
    ) {
        self.transactionCreator = transactionCreator
        self.transactionSender = transactionSender
        self.transactionSigner = transactionSigner
        self.currencyMapper = currencyMapper
    }
}

// MARK: - TransactionSendable

extension ExchangeTransactionSender: TransactionSendable {
    func sendTransaction(_ info: ExchangeTransactionDataModel) async throws -> TransactionSendResult {
        let transaction = try buildTransaction(for: info)
        return try await transactionSender.send(transaction, signer: transactionSigner).async()
    }
}

// MARK: - Private

private extension ExchangeTransactionSender {
    func buildTransaction(for info: ExchangeTransactionDataModel) throws -> Transaction {
        let amount = createAmount(from: info.sourceCurrency, amount: info.sourceCurrency.convertFromWEI(value: info.amount))
        let fee = try createAmount(from: info.sourceBlockchain, amount: info.fee)

        var transaction = try transactionCreator.createTransaction(
            amount: amount,
            fee: fee,
            sourceAddress: info.sourceAddress,
            destinationAddress: info.destinationAddress,
            changeAddress: info.sourceAddress,
            contractAddress: info.destinationAddress
        )

        transaction.params = EthereumTransactionParams(data: info.txData, gasLimit: info.gasValue)
        return transaction
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
