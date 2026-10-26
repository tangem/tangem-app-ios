//
//  SuiTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import WalletCore

final class SuiTransactionBuilder {
    private let walletAddress: String
    private let publicKey: Wallet.PublicKey
    private let decimalValue: Decimal
    private let nonceProvider: () -> UInt32
    private var coins: [SuiCoinObject]
    private var addressBalances: [SuiCoinObject.CoinType: Decimal]

    private var suiCoinsBalance: Decimal {
        coins(of: .sui).sumOfBalances
    }

    private var suiAddressBalance: Decimal {
        addressBalances[.sui] ?? .zero
    }

    private var gasSource: GasSource {
        let coinsBalance = suiCoinsBalance

        if coinsBalance >= Constants.preferredCoinGasBalance || coinsBalance >= suiAddressBalance {
            return .coins
        }

        return .addressBalance
    }

    private var gasSourceBalance: Decimal {
        switch gasSource {
        case .coins: Array(coins(of: .sui).prefix(Constants.maxGasPaymentObjects)).sumOfBalances
        case .addressBalance: suiAddressBalance
        }
    }

    var requiresServiceInfo: Bool {
        gasSource == .addressBalance
    }

    init(
        walletAddress: String,
        publicKey: Wallet.PublicKey,
        decimalValue: Decimal,
        nonceProvider: @escaping () -> UInt32 = { UInt32.random(in: .min ... .max) }
    ) {
        self.walletAddress = walletAddress
        self.publicKey = publicKey
        self.decimalValue = decimalValue
        self.nonceProvider = nonceProvider

        coins = []
        addressBalances = [:]
    }

    func update(coins: [SuiCoinObject], balances: [SuiBalance]) {
        self.coins = coins
        addressBalances = balances.reduce(into: [:]) { result, balance in
            result[balance.coinType, default: .zero] += balance.addressBalance
        }
    }

    func buildForInspect(amount: Amount, destination: String, referenceGasPrice: Decimal, serviceInfo: SuiServiceInfo?) throws -> String {
        let transactionData: SuiTransactionData

        switch amount.type {
        case .coin:
            transactionData = try makeInspectCoinTransactionData(
                amount: amount,
                destination: destination,
                referenceGasPrice: referenceGasPrice,
                serviceInfo: serviceInfo
            )

        case .token(let token):
            transactionData = try makeInspectTokenTransactionData(
                amount: amount,
                token: token,
                destination: destination,
                referenceGasPrice: referenceGasPrice,
                serviceInfo: serviceInfo
            )

        default:
            throw BlockchainSdkError.failedToBuildTx
        }

        return transactionData.serialize().base64EncodedString()
    }

    func buildTransaction(transaction: Transaction, serviceInfo: SuiServiceInfo?) throws -> String {
        guard let suiFeeParameters = transaction.fee.parameters as? SuiFeeParameters else {
            throw BlockchainSdkError.failedToBuildTx
        }

        let transactionData: SuiTransactionData

        switch transaction.amount.type {
        case .coin:
            transactionData = try makeCoinTransactionData(
                amount: transaction.amount.value * decimalValue,
                destination: transaction.destinationAddress,
                fee: suiFeeParameters,
                serviceInfo: serviceInfo
            )

        case .token(let token):
            transactionData = try makeTokenTransactionData(
                amount: transaction.amount.value * token.decimalValue,
                coinType: SuiCoinObject.CoinType(string: token.contractAddress),
                destination: transaction.destinationAddress,
                fee: suiFeeParameters,
                serviceInfo: serviceInfo
            )

        default:
            throw BlockchainSdkError.failedToBuildTx
        }

        return transactionData.serialize().base64EncodedString()
    }

    func buildForSign(transactionBytes: String) throws -> Data {
        let signingInput = makeSigningInput(transactionBytes: transactionBytes)
        let preImageHashes = try TransactionCompiler.preImageHashes(coinType: .sui, txInputData: signingInput.serializedData())
        let preSigningOutput = try TxCompilerPreSigningOutput(serializedBytes: preImageHashes)

        guard preSigningOutput.error == .ok else {
            BSDKLogger.error(error: "SuiPreSigningOutput has a error: \(preSigningOutput.errorMessage)")
            throw BlockchainSdkError.failedToBuildTx
        }

        return preSigningOutput.dataHash
    }

    func buildForSend(transactionBytes: String, signature: Data) throws -> (txBytes: String, signature: String) {
        let signingInput = makeSigningInput(transactionBytes: transactionBytes)

        let compiled = try TransactionCompiler.compileWithSignaturesAndPubKeyType(
            coinType: .sui,
            txInputData: signingInput.serializedData(),
            signatures: signature.asDataVector(),
            publicKeys: publicKey.blockchainKey.asDataVector(),
            pubKeyType: .ed25519
        )

        let output = try SuiSigningOutput(serializedBytes: compiled)

        guard output.error == .ok else {
            BSDKLogger.error(error: "SuiSigningOutput has a error: \(output.errorMessage)")
            throw BlockchainSdkError.failedToBuildTx
        }

        return (output.unsignedTx, output.signature)
    }

    func checkIfSuiBalanceIsNotEnoughForTokenTransaction() -> Bool {
        gasSourceBalance < decimalValue
    }

    // MARK: - Inspect

    private func makeInspectCoinTransactionData(
        amount: Amount,
        destination: String,
        referenceGasPrice: Decimal,
        serviceInfo: SuiServiceInfo?
    ) throws -> SuiTransactionData {
        let totalAmount = suiCoinsBalance + suiAddressBalance
        let decimalAmount = amount.value * decimalValue
        let isSendMax = decimalAmount == totalAmount

        let coinsBalanceAfterAmount = suiCoinsBalance - decimalAmount
        let availableBudget = if isSendMax {
            totalAmount - Constants.oneMist
        } else if gasSource == .coins, coinsBalanceAfterAmount >= Constants.preferredCoinGasBalance {
            coinsBalanceAfterAmount
        } else {
            totalAmount - decimalAmount
        }
        let gasSourceLimit = isSendMax && gasSource == .addressBalance ? gasSourceBalance - Constants.oneMist : gasSourceBalance
        let budget = min(availableBudget, gasSourceLimit, SUIUtils.suiGasBudgetMaxValue)
        let inputAmount = isSendMax ? totalAmount - budget : decimalAmount

        return try makeCoinTransactionData(
            amount: inputAmount,
            destination: destination,
            fee: .init(gasPrice: referenceGasPrice, gasBudget: budget),
            serviceInfo: serviceInfo
        )
    }

    private func makeInspectTokenTransactionData(
        amount: Amount,
        token: Token,
        destination: String,
        referenceGasPrice: Decimal,
        serviceInfo: SuiServiceInfo?
    ) throws -> SuiTransactionData {
        let budget = min(gasSourceBalance, SUIUtils.suiGasBudgetMaxValue)

        return try makeTokenTransactionData(
            amount: amount.value * token.decimalValue,
            coinType: SuiCoinObject.CoinType(string: token.contractAddress),
            destination: destination,
            fee: .init(gasPrice: referenceGasPrice, gasBudget: budget),
            serviceInfo: serviceInfo
        )
    }

    // MARK: - Transaction data

    private func makeCoinTransactionData(
        amount: Decimal,
        destination: String,
        fee: SuiFeeParameters,
        serviceInfo: SuiServiceInfo?
    ) throws -> SuiTransactionData {
        let recipient = try SuiTransactionData.Address(destination)
        var builder = SuiProgrammableTransactionBuilder()

        switch gasSource {
        case .coins:
            let suiCoins = coins(of: .sui)
            let requiredAmount = amount + fee.gasBudget
            let coinsAmount = suiCoins.sumOfBalances >= requiredAmount
                ? requiredAmount
                : max(requiredAmount - suiAddressBalance, fee.gasBudget)
            let selectedCoins = selectCoins(from: suiCoins, for: coinsAmount)
            let payment = Array(selectedCoins.prefix(Constants.maxGasPaymentObjects))
            let withdrawalAmount = requiredAmount - selectedCoins.sumOfBalances

            var sourceArguments = try selectedCoins.dropFirst(Constants.maxGasPaymentObjects).map { try builder.object($0) }

            if withdrawalAmount > .zero {
                try sourceArguments.append(builder.redeemFunds(amount: withdrawalAmount.uint64Value, coinType: .sui))
            }

            try builder.mergeCoins(.gasCoin, sourceArguments)

            let coin = try builder.splitCoin(.gasCoin, amount: amount.uint64Value)
            try builder.transferObjects([coin], to: recipient)

            return try makeTransactionData(builder: builder, payment: payment, fee: fee, expiration: .none)

        case .addressBalance:
            let coin = try makeCoin(amount: amount, coinType: .sui, builder: &builder)
            try builder.transferObjects([coin], to: recipient)

            return try makeTransactionData(
                builder: builder,
                payment: [],
                fee: fee,
                expiration: makeValidDuringExpiration(serviceInfo: serviceInfo)
            )
        }
    }

    private func makeTokenTransactionData(
        amount: Decimal,
        coinType: SuiCoinObject.CoinType,
        destination: String,
        fee: SuiFeeParameters,
        serviceInfo: SuiServiceInfo?
    ) throws -> SuiTransactionData {
        let recipient = try SuiTransactionData.Address(destination)
        var builder = SuiProgrammableTransactionBuilder()

        let coin = try makeCoin(amount: amount, coinType: coinType, builder: &builder)
        try builder.transferObjects([coin], to: recipient)

        switch gasSource {
        case .coins:
            let payment = selectCoins(from: coins(of: .sui), for: fee.gasBudget)
            return try makeTransactionData(builder: builder, payment: payment, fee: fee, expiration: .none)

        case .addressBalance:
            return try makeTransactionData(
                builder: builder,
                payment: [],
                fee: fee,
                expiration: makeValidDuringExpiration(serviceInfo: serviceInfo)
            )
        }
    }

    private func makeCoin(
        amount: Decimal,
        coinType: SuiCoinObject.CoinType,
        builder: inout SuiProgrammableTransactionBuilder
    ) throws -> SuiTransactionData.Argument {
        let selectedCoins = selectCoins(from: coins(of: coinType), for: amount)
        let withdrawalAmount = amount - selectedCoins.sumOfBalances

        guard let primaryCoin = selectedCoins.first else {
            return try builder.redeemFunds(amount: amount.uint64Value, coinType: coinType)
        }

        let primaryArgument = try builder.object(primaryCoin)
        var sourceArguments = try selectedCoins.dropFirst().map { try builder.object($0) }

        if withdrawalAmount > .zero {
            try sourceArguments.append(builder.redeemFunds(amount: withdrawalAmount.uint64Value, coinType: coinType))
        }

        try builder.mergeCoins(primaryArgument, sourceArguments)

        return try builder.splitCoin(primaryArgument, amount: amount.uint64Value)
    }

    private func makeTransactionData(
        builder: SuiProgrammableTransactionBuilder,
        payment: [SuiCoinObject],
        fee: SuiFeeParameters,
        expiration: SuiTransactionData.Expiration
    ) throws -> SuiTransactionData {
        let sender = try SuiTransactionData.Address(walletAddress)

        return try SuiTransactionData(
            inputs: builder.inputs,
            commands: builder.commands,
            sender: sender,
            gasData: SuiTransactionData.GasData(
                payment: payment.map(SuiTransactionData.ObjectRef.init(coin:)),
                owner: sender,
                price: fee.gasPrice.uint64Value,
                budget: fee.gasBudget.uint64Value
            ),
            expiration: expiration
        )
    }

    private func makeValidDuringExpiration(serviceInfo: SuiServiceInfo?) throws -> SuiTransactionData.Expiration {
        guard let serviceInfo else {
            throw BlockchainSdkError.failedToBuildTx
        }

        let chainIdentifier = Base58.decode(serviceInfo.chainIdentifier)

        guard chainIdentifier.count == Constants.chainIdentifierLength else {
            throw BlockchainSdkError.failedToBuildTx
        }

        return .validDuring(
            minEpoch: serviceInfo.epoch,
            maxEpoch: serviceInfo.epoch + 1,
            chainIdentifier: chainIdentifier,
            nonce: nonceProvider()
        )
    }

    // MARK: - Helpers

    private func makeSigningInput(transactionBytes: String) -> WalletCore.SuiSigningInput {
        WalletCore.SuiSigningInput.with { input in
            input.signDirectMessage = WalletCore.SuiSignDirect.with { $0.unsignedTxMsg = transactionBytes }
        }
    }

    private func coins(of coinType: SuiCoinObject.CoinType) -> [SuiCoinObject] {
        coins
            .filter { $0.coinType == coinType }
            .sorted { lhs, rhs in
                lhs.balance == rhs.balance ? lhs.coinObjectId < rhs.coinObjectId : lhs.balance > rhs.balance
            }
    }

    private func selectCoins(from coins: [SuiCoinObject], for amount: Decimal) -> [SuiCoinObject] {
        var suitableCoins = [SuiCoinObject]()
        var total = Decimal.zero

        for coin in coins {
            suitableCoins.append(coin)
            total += coin.balance

            if total >= amount {
                break
            }
        }

        return suitableCoins
    }
}

// MARK: - GasSource

private extension SuiTransactionBuilder {
    enum GasSource {
        case coins
        case addressBalance
    }
}

// MARK: - Constants

private extension SuiTransactionBuilder {
    enum Constants {
        static let preferredCoinGasBalance = Decimal(50_000_000)
        static let chainIdentifierLength = 32
        static let maxGasPaymentObjects = 256
        /// The smallest SUI unit, 10^-9 SUI. Builder amounts are expressed in mist.
        static let oneMist: Decimal = 1.0
    }
}

// MARK: - Sum of balances

private extension Array where Element == SuiCoinObject {
    var sumOfBalances: Decimal {
        reduce(into: Decimal.zero) { $0 += $1.balance }
    }
}
