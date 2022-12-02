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
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

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
    func getWalletAddress(currency: Currency) -> String? {
        print("addressNames", walletModel.wallet.addresses)

        return walletModel.wallet.address
    }

    func getBalance(currency: Currency) -> Decimal {
        if currency.isToken, let token = currency.asToken() {
            return walletModel.getDecimalBalance(for: .token(value: token))
        }

        return walletModel.getDecimalBalance(for: .coin)
    }

    func getFiatBalance(currency: Currency, amount: Decimal) async throws -> Decimal {
        if let fiat = getFiatBalanceFromWalletModel(currency: currency, amount: amount) {
            return fiat
        }

        return try await getFiatBalanceThroughAddToWalletModel(currency: currency, amount: amount)
    }

    func getFee(currency: Currency, amount: Decimal, destination: String) async throws -> [Decimal] {
        let amount = createAmount(from: currency, amount: amount)

        let fees = try await walletManager.getFee(amount: amount, destination: destination).async()
        return fees.map { $0.value }
    }
}

// MARK: - TransactionBuilder

extension BlockchainNetworkService: TransactionBuilder {
    typealias Transaction = BlockchainSdk.Transaction

    func buildTransaction(for info: ExchangeTransactionInfo, fee: Decimal) throws -> Transaction {
        let transactionInfo = TransactionInfo(
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
    func createTransaction(for info: TransactionInfo) throws -> Transaction {
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

    func getFiatBalanceFromWalletModel(currency: Currency, amount: Decimal) -> Decimal? {
        switch currency.currencyType {
        case .coin:
            let amount = Amount(type: .coin, currencySymbol: currency.symbol, value: amount, decimals: currency.decimalCount)
            if let fiat = walletModel.getFiat(for: amount, roundingMode: .plain) {
                return fiat
            }

        case .token:
            guard let token = currency.asToken() else {
                assertionFailure("Currency isn't token")
                return 0
            }

            let amount = Amount(with: token, value: amount)
            if let fiat = walletModel.getFiat(for: amount, roundingMode: .plain) {
                return fiat
            }
        }

        return nil
    }

    func getFiatBalanceThroughAddToWalletModel(currency: Currency, amount: Decimal) async throws -> Decimal {
        let rates = try await tangemApiService.loadRates(for: [currency.id]).async()
        let currencyRate: Decimal

        switch currency.currencyType {
        case .coin:
            guard let rate = rates[currency.blockchain.networkId] else {
                throw CommonError.noData
            }
            currencyRate = rate
        case .token:
            guard let rate = rates[currency.id] else {
                throw CommonError.noData
            }

            currencyRate = rate
        }

        let fiatValue = amount * currencyRate
        if fiatValue == 0 {
            return 0
        }

        return max(fiatValue, 0.01).rounded(scale: 2, roundingMode: .plain)
    }
}

private extension BlockchainNetworkService {
    struct TransactionInfo {
        let currency: Currency
        let amount: Decimal
        let fee: Decimal
        let destination: String
        let sourceAddress: String?
        let changeAddress: String?

        init(
            currency: Currency,
            amount: Decimal,
            fee: Decimal,
            destination: String,
            sourceAddress: String? = nil,
            changeAddress: String? = nil
        ) {
            self.currency = currency
            self.amount = amount
            self.fee = fee
            self.destination = destination
            self.sourceAddress = sourceAddress
            self.changeAddress = changeAddress
        }
    }
}

private extension Currency {
    func asToken() -> Token? {
        guard let contractAddress = contractAddress else {
            return nil
        }

        return Token(
            name: name,
            symbol: symbol,
            contractAddress: contractAddress,
            decimalCount: decimalCount,
            id: id
        )
    }
}
