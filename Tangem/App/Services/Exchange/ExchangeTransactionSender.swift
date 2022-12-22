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
    private let sender: TransactionSender
    private let signer: TransactionSigner
    private let currencyMapper: CurrencyMapping

    init(
        sender: TransactionSender,
        signer: TransactionSigner,
        currencyMapper: CurrencyMapping
    ) {
        self.sender = sender
        self.signer = signer
        self.currencyMapper = currencyMapper
    }
}

// MARK: - TransactionSendable

extension ExchangeTransactionSender: TransactionSendable {
    func sendTransaction(_ info: ExchangeTransactionDataModel) async throws {
        try await send(buildTransaction(for: info))
    }
}

// MARK: - Private

private extension ExchangeTransactionSender {
    func buildTransaction(for info: ExchangeTransactionDataModel) throws -> Transaction {
        let amount = createAmount(from: info.sourceCurrency, amount: info.sourceCurrency.convertFromWEI(value: info.amount))
        let fee = try createAmount(from: info.sourceBlockchain, amount: info.fee)

        var transaction = try sender.createTransaction(
            amount: amount,
            fee: fee,
            destinationAddress: info.destinationAddress,
            sourceAddress: info.sourceAddress
        )

        transaction.params = EthereumTransactionParams(data: info.txData, gasLimit: info.gasValue)
        return transaction
    }

    func send(_ transaction: Transaction) async throws {
        try await sender.send(transaction, signer: signer).async()
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
