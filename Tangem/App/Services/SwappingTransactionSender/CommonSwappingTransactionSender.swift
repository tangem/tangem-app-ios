//
//  CommonSwappingTransactionSender.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import TangemSwapping
import BlockchainSdk
import BigInt

struct CommonSwappingTransactionSender {
    private let transactionCreator: TransactionCreator
    private let transactionSender: TransactionSender
    private let transactionSigner: TransactionSigner
    private let ethereumNetworkProvider: EthereumNetworkProvider
    private let currencyMapper: CurrencyMapping

    init(
        transactionCreator: TransactionCreator,
        transactionSender: TransactionSender,
        transactionSigner: TransactionSigner,
        ethereumNetworkProvider: EthereumNetworkProvider,
        currencyMapper: CurrencyMapping
    ) {
        self.transactionCreator = transactionCreator
        self.transactionSender = transactionSender
        self.transactionSigner = transactionSigner
        self.ethereumNetworkProvider = ethereumNetworkProvider
        self.currencyMapper = currencyMapper
    }
}

// MARK: - SwappingTransactionSender

extension CommonSwappingTransactionSender: SwappingTransactionSender {
    func sendTransaction(_ info: SwappingTransactionData) async throws -> TransactionSendResult {
        let nonce = try await ethereumNetworkProvider.getTxCount(info.sourceAddress).async()
        let transaction = try buildTransaction(for: info, nonce: nonce)
        return try await transactionSender.send(transaction, signer: transactionSigner).async()
    }
}

// MARK: - Private

private extension CommonSwappingTransactionSender {
    func buildTransaction(for info: SwappingTransactionData, nonce: Int) throws -> Transaction {
        let gasModel = info.gas

        let amount = createAmount(from: info.sourceCurrency, amount: info.value)
        let feeAmount = try createAmount(from: info.sourceBlockchain, amount: gasModel.fee)
        let feeParameters = EthereumFeeParameters(gasLimit: BigUInt(gasModel.gasLimit), gasPrice: BigUInt(gasModel.gasPrice))
        let fee = Fee(feeAmount, parameters: feeParameters)

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

        transaction.params = EthereumTransactionParams(
            data: info.txData,
            nonce: nonce
        )

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

    func createAmount(from swappingBlockchain: SwappingBlockchain, amount: Decimal) throws -> Amount {
        guard let blockchain = Blockchain(from: swappingBlockchain.networkId) else {
            throw CommonError.noData
        }

        return Amount(with: blockchain, value: amount)
    }
}
