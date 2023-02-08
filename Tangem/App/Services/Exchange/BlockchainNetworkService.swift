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
    private let walletModel: WalletModel
    private let currencyMapper: CurrencyMapping

    private var balances: [Amount.AmountType: Decimal] = [:]
    private var walletManager: WalletManager { walletModel.walletManager }

    init(walletModel: WalletModel, currencyMapper: CurrencyMapping) {
        self.walletModel = walletModel
        self.currencyMapper = currencyMapper

        balances = walletModel.wallet.amounts.reduce(into: [:]) {
            $0[$1.key] = $1.value.value.rounded(scale: $1.value.decimals, roundingMode: .down)
        }
    }
}

// MARK: - BlockchainDataProvider

extension BlockchainNetworkService: TangemExchange.BlockchainDataProvider {
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

        return 0
    }
}
