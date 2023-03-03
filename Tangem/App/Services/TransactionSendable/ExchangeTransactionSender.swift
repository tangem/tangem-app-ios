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
    private let ethereumGasLoader: EthereumGasLoader
    private let currencyMapper: CurrencyMapping

    init(
        transactionCreator: TransactionCreator,
        transactionSender: TransactionSender,
        transactionSigner: TransactionSigner,
        ethereumGasLoader: EthereumGasLoader,
        currencyMapper: CurrencyMapping
    ) {
        self.transactionCreator = transactionCreator
        self.transactionSender = transactionSender
        self.transactionSigner = transactionSigner
        self.ethereumGasLoader = ethereumGasLoader
        self.currencyMapper = currencyMapper
    }
}

// MARK: - TransactionSendable

extension ExchangeTransactionSender: TransactionSendable {
    func sendTransaction(_ info: ExchangeTransactionDataModel) async throws -> TransactionSendResult {
        let transaction = try await buildTransaction(for: info)
        return try await transactionSender.send(transaction, signer: transactionSigner).async()
    }
}

// MARK: - Private

private extension ExchangeTransactionSender {
    func buildTransaction(for info: ExchangeTransactionDataModel) async throws -> Transaction {
        let sourceAmount = info.sourceCurrency.convertFromWEI(value: info.value)
        let amount = createAmount(from: info.sourceCurrency, amount: sourceAmount)
        let gasLimit = try await ethereumGasLoader.getGasLimit(
            to: info.destinationAddress,
            from: info.sourceAddress,
            value: amount.encodedForSend,
            data: "0x\(info.txData.hexString)"
        ).async()

        let fee = try createAmount(from: info.sourceBlockchain, amount: info.fee)

        var transaction = Transaction(
            amount: amount,
            fee: fee,
            sourceAddress: info.sourceAddress,
            destinationAddress: info.destinationAddress,
            changeAddress: info.sourceAddress,
            contractAddress: info.destinationAddress,
            date: Date(),
            status: .unconfirmed
        )

        transaction.params = EthereumTransactionParams(data: info.txData, gasLimit: Int(gasLimit))
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
