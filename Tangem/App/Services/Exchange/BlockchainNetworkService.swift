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
    private var walletManager: WalletManager { walletModel.walletManager }

    init(walletModel: WalletModel, currencyMapper: CurrencyMapping) {
        self.walletModel = walletModel
        self.currencyMapper = currencyMapper
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

        if let balance = walletModel.getDecimalBalance(for: amountType) {
            return balance
        }

        return try await getBalanceThroughUpdateWalletModel(amountType: amountType)
    }

    func getFiatBalance(currency: Currency, amount: Decimal) async throws -> Decimal {
        if let fiat = getFiatBalanceFromWalletModel(currency: currency, amount: amount) {
            return fiat
        }

        return try await getFiatBalanceThroughLoadRates(currency: currency, amount: amount)
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
