//
//  ExchangeWalletDataProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemExchange

class ExchangeWalletDataProvider {
    private let wallet: Wallet
    private let ethereumGasLoader: EthereumGasLoader
    private let optimismGasLoader: OptimismGasLoader?
    private let ethereumNetworkProvider: EthereumNetworkProvider
    private let currencyMapper: CurrencyMapping

    private var balances: [Amount.AmountType: Decimal] = [:]
    private var walletAddress: String { wallet.address }

    init(
        wallet: Wallet,
        ethereumGasLoader: EthereumGasLoader,
        optimismGasLoader: OptimismGasLoader?,
        ethereumNetworkProvider: EthereumNetworkProvider,
        currencyMapper: CurrencyMapping
    ) {
        self.wallet = wallet
        self.ethereumGasLoader = ethereumGasLoader
        self.optimismGasLoader = optimismGasLoader
        self.ethereumNetworkProvider = ethereumNetworkProvider
        self.currencyMapper = currencyMapper

        balances = wallet.amounts.reduce(into: [:]) {
            $0[$1.key] = $1.value.value.rounded(scale: $1.value.decimals, roundingMode: .down)
        }
    }
}

// MARK: - WalletDataProvider

extension ExchangeWalletDataProvider: WalletDataProvider {
    func getWalletAddress(currency: Currency) -> String? {
        guard wallet.blockchain.networkId == currency.blockchain.networkId else {
            assertionFailure("Incorrect WalletModel")
            return nil
        }

        return walletAddress
    }

    func getGasModel(
        sourceAddress: String,
        destinationAddress: String,
        data: Data,
        blockchain: ExchangeBlockchain,
        value: Decimal
    ) async throws -> EthereumGasDataModel {
        let hexData = data.hexString.addHexPrefix()

        switch blockchain {
        case .optimism:
            async let l1GasModel = getOptimismGasModel(hexData: hexData, blockchain: blockchain)
            async let l2GasModel = getEtheriumGasModel(
                sourceAddress: sourceAddress,
                destinationAddress: destinationAddress,
                hexData: hexData,
                blockchain: blockchain,
                value: value,
                increasedPolicy: .noRaise
            )

            return try await EthereumGasDataModel(
                blockchain: blockchain,
                gasPrice: l2GasModel.gasPrice,
                gasLimit: l2GasModel.gasLimit,
                fee: l2GasModel.fee + l1GasModel.fee
            )

        default:
            return try await getEtheriumGasModel(
                sourceAddress: sourceAddress,
                destinationAddress: destinationAddress,
                hexData: hexData,
                blockchain: blockchain,
                value: value,
                increasedPolicy: .mediumRaise
            )
        }
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
        guard wallet.blockchain.networkId == blockchain.networkId else {
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

private extension ExchangeWalletDataProvider {
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

    func createAmount(from blockchain: ExchangeBlockchain, amount: Decimal) -> Amount {
        Amount(
            type: .coin,
            currencySymbol: blockchain.symbol,
            value: amount,
            decimals: blockchain.decimalCount
        )
    }

    func getBalanceThroughUpdateWalletModel(amountType: Amount.AmountType) async throws -> Decimal {
        guard let token = amountType.token else {
            AppLog.shared.debug("WalletModel can't load balance for amountType \(amountType)")
            return 0
        }

        let loadedBalances = try await ethereumNetworkProvider.getTokensBalance(walletAddress, tokens: [token]).async()

        if let balance = loadedBalances[token] {
            balances[amountType] = balance
            return balance
        }

        AppLog.shared.debug("WalletModel haven't balance for token \(token)")
        return 0
    }

    func getEtheriumGasModel(
        sourceAddress: String,
        destinationAddress: String,
        hexData: String,
        blockchain: ExchangeBlockchain,
        value: Decimal,
        increasedPolicy: GasLimitPolicy
    ) async throws -> EthereumGasDataModel {
        let amount = createAmount(from: blockchain, amount: value)

        async let price = ethereumGasLoader.getGasPrice().async()
        async let limit = ethereumGasLoader.getGasLimit(
            to: destinationAddress,
            from: sourceAddress,
            value: amount.encodedForSend,
            data: hexData
        ).async()

        let gasLimit = try await increasedPolicy.value(for: Int(limit))
        let fee = try await gasLimit * Int(price)

        return try await EthereumGasDataModel(
            blockchain: blockchain,
            gasPrice: Int(price),
            gasLimit: Int(limit),
            fee: blockchain.convertFromWEI(value: Decimal(fee))
        )
    }

    func getOptimismGasModel(hexData: String, blockchain: ExchangeBlockchain) async throws -> EthereumGasDataModel {
        guard let optimismGasLoader = optimismGasLoader else {
            throw CommonError.noData
        }

        async let price = optimismGasLoader.getLayer1GasPrice().async()
        async let limit = optimismGasLoader.getLayer1GasLimit(data: hexData).async()

        let gasLimit = try await Int(limit)
        let gasPrice = try await Int(price)

        return try await EthereumGasDataModel(
            blockchain: blockchain,
            gasPrice: Int(price),
            gasLimit: Int(limit),
            fee: blockchain.convertFromWEI(value: Decimal(gasLimit * gasPrice))
        )
    }
}

extension ExchangeWalletDataProvider {
    enum GasLimitPolicy {
        case noRaise
        case lowRaise
        case mediumRaise
        case highRaise

        func value(for value: Int) -> Int {
            switch self {
            case .noRaise:
                return value
            case .lowRaise:
                return value * 110 / 100
            case .mediumRaise:
                return value * 125 / 100
            case .highRaise:
                return value * 150 / 100
            }
        }
    }
}
