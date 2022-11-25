//
//  BlockchainNetworkService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemExchange

struct BlockchainNetworkService {
    private let walletModel: WalletModel
    private let signer: TransactionSigner

    private var walletManager: WalletManager { walletModel.walletManager }

    init(walletModel: WalletModel, signer: TransactionSigner) {
        self.walletModel = walletModel
        self.signer = signer
    }
}

// MARK: - BlockchainInfoProvider

extension BlockchainNetworkService: BlockchainInfoProvider {
    func getBalance(currency: Currency) async throws -> Decimal {
        if currency.isToken, let token = currency.asToken() {
            return walletModel.getDecimalBalance(for: .token(value: token))
        }
        
        return walletModel.getDecimalBalance(for: .coin)
    }

    func getFee(currency: Currency, amount: Decimal, destination: String) async throws -> [Decimal] {
        let amount = createAmount(from: currency, amount: amount)

        return try await walletManager
            .getFee(amount: amount, destination: destination)
            .map { $0.map { $0.value } }
            .eraseToAnyPublisher()
            .async()
    }
}

// MARK: - TransactionBuilder

extension BlockchainNetworkService: TransactionBuilder {
    typealias Transaction = BlockchainSdk.Transaction

    func buildTransaction(for info: SwapTransactionInfo, fee: Decimal) throws -> Transaction {
        let transactionInfo = ExchangeTransactionInfo(
            currency: info.currency,
            amount: info.amount,
            fee: fee,
            destination: info.destination
        )

        var tx = try createTransaction(for: transactionInfo)
        tx.params = EthereumTransactionParams(data: info.oneInchTxData)

        return tx
    }

    /// We don't have special method for sing transaction
    /// Transaction will be signed when it will be sended
    func sign(_ transaction: Transaction) async throws -> Transaction {
        return transaction
    }

    func send(_ transaction: Transaction) async throws {
        try await walletManager.send(transaction, signer: signer).async()
    }
}

// MARK: - Private

private extension BlockchainNetworkService {
    func createTransaction(for info: ExchangeTransactionInfo) throws -> Transaction {
        let amount = createAmount(from: info.currency, amount: info.amount)
        let fee = createAmount(from: info.currency, amount: info.fee)

        return try walletManager.createTransaction(amount: amount,
                                                   fee: fee,
                                                   destinationAddress: info.destination,
                                                   sourceAddress: info.sourceAddress,
                                                   changeAddress: info.changeAddress)
    }

    func createAmount(from currency: Currency, amount: Decimal) -> Amount {
        if let token = currency.asToken() {
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

private extension Currency {
    func asToken() -> Token? {
        guard let contractAddress = contractAddress else {
            return nil
        }

        return Token(name: name, symbol: symbol, contractAddress: contractAddress, decimalCount: decimalCount)
    }
}
