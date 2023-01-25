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
    private let currencyMapper: CurrencyMapping

    /// Collect rates for calculate fiat balance
    private var rates: [String: Decimal] = [:]
    private var balances: [Amount.AmountType: Decimal] = [:]
    private var walletManager: WalletManager { walletModel.walletManager }

    init(walletModel: WalletModel, currencyMapper: CurrencyMapping) {
        self.walletModel = walletModel
        self.currencyMapper = currencyMapper

        rates = walletModel.rates
        balances = walletModel.wallet.amounts.reduce(into: [:]) {
            $0[$1.key] = $1.value.value.rounded(scale: $1.value.decimals, roundingMode: .down)
        }
    }
}

// MARK: - BlockchainDataProvider

extension BlockchainNetworkService: TangemExchange.BlockchainDataProvider {
    func addTokenToWallet(currency: Currency) {
        guard let token = currencyMapper.mapToToken(currency: currency) else {
            return
        }

        walletModel.addTokens([token])
    }

    func updateWallet() async throws {
        try await walletModel.update(silent: true).async()
    }

    func hasPendingTransaction(currency: Currency, to spenderAddress: String) -> Bool {
        let outgoing = walletModel.wallet.pendingOutgoingTransactions

        return outgoing.contains(where: { $0.destinationAddress == spenderAddress })
    }

    func getWalletAddress(currency: Currency) -> String? {
        let blockchain = walletModel.blockchainNetwork.blockchain
        guard blockchain.networkId == currency.blockchain.networkId else {
            assertionFailure("Incorrect WalletModel")
            return nil
        }

        return walletModel.wallet.address
    }

    func getBalance(for currency: Currency) async throws -> Decimal {
        let amountType: Amount.AmountType

        switch currency.currencyType {
        case .token:
            guard let token = currencyMapper.mapToToken(currency: currency) else {
                assertionFailure("Currency isn't a token")
                return 0
            }

            amountType = Amount.AmountType.token(value: token)
        case .coin:
            amountType = Amount.AmountType.coin
        }

        if let balance = balances[amountType] {
            return balance
        }

        var balance = try await getBalanceThroughUpdateWalletModel(amountType: amountType)
        balance.round(scale: currency.decimalCount, roundingMode: .down)

        balances[amountType] = balance

        return balance
    }

    func getBalance(for blockchain: ExchangeBlockchain) async throws -> Decimal {
        guard walletModel.blockchainNetwork.blockchain.networkId == blockchain.networkId else {
            assertionFailure("Incorrect WalletModel")
            return 0
        }

        if let balance = balances[.coin] {
            return balance
        }

        let balance = try await getBalanceThroughUpdateWalletModel(amountType: .coin)
        balances[.coin] = balance
        return balance
    }

    func getFiat(for currency: Currency, amount: Decimal) async throws -> Decimal {
        let id = currency.isToken ? currency.id : currency.blockchain.id
        let rate = try await getFiatRate(currencyId: id)
        return mapToFiat(amount: amount, rate: rate)
    }

    func getFiat(for blockchain: ExchangeBlockchain, amount: Decimal) async throws -> Decimal {
        let rate = try await getFiatRate(currencyId: blockchain.id)
        return mapToFiat(amount: amount, rate: rate)
    }
}

// MARK: - Private

private extension BlockchainNetworkService {
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

    func getFiatRateFor(for currency: Currency) async throws -> Decimal {
        let id = currency.isToken ? currency.id : currency.blockchain.id
        return try await getFiatRate(currencyId: id)
    }

    func getFiatRateFor(for blockchain: ExchangeBlockchain) async throws -> Decimal {
        try await getFiatRate(currencyId: blockchain.id)
    }

    func getFiatBalanceFromWalletModel(currency: Currency, amount: Decimal) -> Decimal? {
        let amount = createAmount(from: currency, amount: amount)
        if let fiat = walletModel.getFiat(for: amount, roundingType: .default(roundingMode: .plain)) {
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

        /// Think about it, because we unnecessary updates all tokens in walletModel
        try await walletModel.update(silent: true).async()

        if let balance = walletModel.getDecimalBalance(for: amountType) {
            return balance
        }

        assertionFailure("WalletModel haven't balance for coin")
        return 0
    }

    func getFiatRate(currencyId: String) async throws -> Decimal {
        var currencyRate = rates[currencyId]

        if currencyRate == nil {
            let loadedRates = try await tangemApiService.loadRates(for: [currencyId]).async()
            currencyRate = loadedRates[currencyId]
        }

        guard let currencyRate else {
            throw CommonError.noData
        }

        rates[currencyId] = currencyRate

        return currencyRate
    }

    func mapToFiat(amount: Decimal, rate: Decimal) -> Decimal {
        let fiatValue = amount * rate
        if fiatValue == 0 {
            return 0
        }

        return max(fiatValue, 0.01).rounded(scale: 2, roundingMode: .plain)
    }
}
