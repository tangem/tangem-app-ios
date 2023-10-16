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
    private let walletModel: WalletModel
    private let transactionSigner: TransactionSigner
    private let ethereumNetworkProvider: EthereumNetworkProvider
    private let currencyMapper: CurrencyMapping

    init(
        walletModel: WalletModel,
        transactionSigner: TransactionSigner,
        ethereumNetworkProvider: EthereumNetworkProvider,
        currencyMapper: CurrencyMapping
    ) {
        self.walletModel = walletModel
        self.transactionSigner = transactionSigner
        self.ethereumNetworkProvider = ethereumNetworkProvider
        self.currencyMapper = currencyMapper
    }
}

// MARK: - SwappingTransactionSender

extension CommonSwappingTransactionSender: SwappingTransactionSender {
    func sendTransaction(_ data: SwappingTransactionData) async throws -> TransactionSendResult {
        let nonce = try await ethereumNetworkProvider.getTxCount(data.sourceAddress).async()
        let transaction = try buildTransaction(for: data, nonce: nonce)
        return try await walletModel.send(transaction, signer: transactionSigner).async()
    }
}

// MARK: - Private

private extension CommonSwappingTransactionSender {
    func buildTransaction(for data: SwappingTransactionData, nonce: Int) throws -> Transaction {
        let gasModel = data.gas

        let amount = createAmount(from: data.sourceCurrency, amount: data.value)
        let feeAmount = try createAmount(from: data.sourceBlockchain, amount: gasModel.fee)
        let feeParameters = EthereumFeeParameters(gasLimit: BigUInt(gasModel.gasLimit), gasPrice: BigUInt(gasModel.gasPrice))
        let fee = Fee(feeAmount, parameters: feeParameters)

        var transaction = Transaction(
            amount: amount,
            fee: fee,
            sourceAddress: data.sourceAddress,
            destinationAddress: data.destinationAddress,
            changeAddress: data.sourceAddress,
            contractAddress: data.destinationAddress
        )

        transaction.params = EthereumTransactionParams(
            data: data.txData,
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
        Amount(
            type: .coin,
            currencySymbol: swappingBlockchain.symbol,
            value: amount,
            decimals: swappingBlockchain.decimalCount
        )
    }
}
