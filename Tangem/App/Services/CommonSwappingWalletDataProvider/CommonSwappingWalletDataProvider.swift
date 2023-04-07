//
//  CommonSwappingWalletDataProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemSwapping

class CommonSwappingWalletDataProvider {
    private let wallet: Wallet
    private let ethereumNetworkProvider: EthereumNetworkProvider
    private let ethereumTransactionProcessor: EthereumTransactionProcessor
    private let currencyMapper: CurrencyMapping

    private var balances: [Amount.AmountType: Decimal] = [:]
    private var walletAddress: String { wallet.address }

    init(
        wallet: Wallet,
        ethereumNetworkProvider: EthereumNetworkProvider,
        ethereumTransactionProcessor: EthereumTransactionProcessor,
        currencyMapper: CurrencyMapping
    ) {
        self.wallet = wallet
        self.ethereumNetworkProvider = ethereumNetworkProvider
        self.ethereumTransactionProcessor = ethereumTransactionProcessor
        self.currencyMapper = currencyMapper

        balances = wallet.amounts.reduce(into: [:]) {
            $0[$1.key] = $1.value.value.rounded(scale: $1.value.decimals, roundingMode: .down)
        }
    }
}

// MARK: - SwappingWalletDataProvider

extension CommonSwappingWalletDataProvider: SwappingWalletDataProvider {
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
        blockchain: SwappingBlockchain,
        value: Decimal
    ) async throws -> EthereumGasDataModel {
        try await getFee(
            blockchain: blockchain,
            value: value,
            data: data,
            destination: destinationAddress,
            gasPolicy: .mediumRaise
        )
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

        var balance = try await getBalanceFromNetwork(amountType: amountType)
        balance.round(scale: currency.decimalCount, roundingMode: .down)

        balances[amountType] = balance

        return balance
    }

    func getBalance(for blockchain: SwappingBlockchain) async throws -> Decimal {
        guard wallet.blockchain.networkId == blockchain.networkId else {
            assertionFailure("Incorrect WalletModel")
            return 0
        }

        if let balance = balances[.coin] {
            return balance
        }

        let balance = try await getBalanceFromNetwork(amountType: .coin)
        balances[.coin] = balance
        return balance
    }
}

// MARK: - Private

private extension CommonSwappingWalletDataProvider {
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

    func createAmount(from blockchain: SwappingBlockchain, amount: Decimal) -> Amount {
        Amount(
            type: .coin,
            currencySymbol: blockchain.symbol,
            value: amount,
            decimals: blockchain.decimalCount
        )
    }

    func getBalanceFromNetwork(amountType: Amount.AmountType) async throws -> Decimal {
        switch amountType {
        case .coin:
            let balance = try await ethereumNetworkProvider.getBalance(walletAddress).async()
            balances[amountType] = balance
            return balance

        case .token(let token):
            let loadedBalances = try await ethereumNetworkProvider.getTokensBalance(
                walletAddress, tokens: [token]
            ).async()

            if let balance = loadedBalances[token] {
                balances[amountType] = balance
                return balance
            }

        case .reserve:
            throw CommonError.notImplemented
        @unknown default:
            throw CommonError.notImplemented
        }

        AppLog.shared.debug("WalletModel haven't balance for amountType \(amountType)")
        return 0
    }

    func getFee(
        blockchain: SwappingBlockchain,
        value: Decimal,
        data: Data,
        destination: String,
        gasPolicy: GasLimitPolicy
    ) async throws -> EthereumGasDataModel {
        let amount = createAmount(from: blockchain, amount: value)

        let fees = try await ethereumTransactionProcessor.getFee(
            destination: destination,
            value: amount.encodedForSend,
            data: data
        ).async()

        guard let lowFeeModel = fees.first,
              let ethFeeParameters = lowFeeModel.parameters as? EthereumFeeParameters else {
            assertionFailure("LowFeeModel don't contains EthereumFeeParameters")
            throw CommonError.noData
        }

        switch blockchain {
        case .optimism:
            return EthereumGasDataModel(
                blockchain: blockchain,
                gasPrice: Int(ethFeeParameters.gasPrice),
                gasLimit: Int(ethFeeParameters.gasLimit),
                fee: lowFeeModel.amount.value
            )
        default:
            let gasLimit = gasPolicy.value(for: Int(ethFeeParameters.gasLimit))
            let gasPrice = Int(ethFeeParameters.gasPrice)

            return EthereumGasDataModel(
                blockchain: blockchain,
                gasPrice: Int(ethFeeParameters.gasPrice),
                gasLimit: Int(ethFeeParameters.gasLimit),
                fee: blockchain.convertFromWEI(value: Decimal(gasLimit * gasPrice))
            )
        }
    }
}

extension CommonSwappingWalletDataProvider {
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
