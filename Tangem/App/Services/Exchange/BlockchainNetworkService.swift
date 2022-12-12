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

class BlockchainNetworkService {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    private let walletModel: WalletModel
    private let signer: TransactionSigner

    /// Collect rates for calculate fiat balance
    private var rates: [String: Decimal] = [:]
    private var walletManager: WalletManager { walletModel.walletManager }

    init(walletModel: WalletModel, signer: TransactionSigner) {
        self.walletModel = walletModel
        self.signer = signer
    }
}

// MARK: - BlockchainDataProvider

extension BlockchainNetworkService: TangemExchange.BlockchainDataProvider {
    func getWalletAddress(currency: Currency) -> String? {
        let blockchain = walletModel.blockchainNetwork.blockchain
        guard blockchain.networkId == currency.blockchain.networkId else {
            assertionFailure("Incorrect WalletModel")
            return nil
        }

        return walletModel.wallet.address
    }

    func getBalance(currency: Currency) async throws -> Decimal {
        switch currency.currencyType {
        case .token:
            guard let token = currency.asToken() else {
                assertionFailure("Currency isn't a token")
                return 0
            }

            let amount = Amount.AmountType.token(value: token)
            if let balance = walletModel.getDecimalBalance(for: amount) {
                return balance
            }

            return try await getBalanceThroughUpdateWalletModel(amountType: amount)

        case .coin:
            let amount = Amount.AmountType.coin
            if let balance = walletModel.getDecimalBalance(for: amount) {
                return balance
            }

            return try await getBalanceThroughUpdateWalletModel(amountType: amount)
        }
    }

    func getFiatBalance(currency: Currency, amount: Decimal) async throws -> Decimal {
        if let fiat = getFiatBalanceFromWalletModel(currency: currency, amount: amount) {
            return fiat
        }

        return try await getFiatBalanceThroughLoadRates(currency: currency, amount: amount)
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
        let amount = createAmount(from: currency, amount: amount)
        if let fiat = walletModel.getFiat(for: amount, roundingMode: .plain) {
            return fiat
        }

        return nil
    }

    func getBalanceThroughUpdateWalletModel(amountType: Amount.AmountType) async throws -> Decimal {
        if let token = amountType.token {
            walletModel.addTokens([token])
        }

        defer {
            if let token = amountType.token {
                walletModel.removeToken(token)
            }
        }

        // Think about it, because we unnecessary updates all tokens in walletModel
        try await walletModel.update(silent: true).async()

        if let balance = walletModel.getDecimalBalance(for: amountType) {
            return balance
        }

        assertionFailure("WalletModel haven't balance for coin")
        return 0
    }

    func getFiatBalanceThroughLoadRates(currency: Currency, amount: Decimal) async throws -> Decimal {
        let id = currency.isToken ? currency.id : currency.blockchain.networkId
        var currencyRate = rates[id]

        if currencyRate == nil {
            let loadedRates = try await tangemApiService.loadRates(for: [currency.id]).async()
            currencyRate = loadedRates[id]
        }

        guard let currencyRate else {
            throw CommonError.noData
        }

        rates[currency.id] = currencyRate
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
