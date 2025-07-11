//
// SuiTransactionBuilder.swift
// BlockchainSdk
//
// Created by [REDACTED_AUTHOR]
// Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import WalletCore

final class SuiTransactionBuilder {
    private static let signatureMock = Data(repeating: 0x01, count: 64)

    private let walletAddress: String
    private let publicKey: Wallet.PublicKey
    private let decimalValue: Decimal
    private var coins: [SuiCoinObject]

    private var coinGas: SuiCoinObject? {
        coins
            .filter { $0.coinType == SuiCoinObject.CoinType.sui }
            .max { $0.balance < $1.balance }
    }

    init(walletAddress: String, publicKey: Wallet.PublicKey, decimalValue: Decimal) {
        self.walletAddress = walletAddress
        self.publicKey = publicKey
        self.decimalValue = decimalValue

        coins = []
    }

    func update(coins: [SuiCoinObject]) {
        self.coins = coins
    }

    func buildForInspect(amount: Amount, destination: String, referenceGasPrice: Decimal) throws -> String {
        switch amount.type {
        case .coin:
            try buildForInspectCoinTransaction(amount: amount, destination: destination, referenceGasPrice: referenceGasPrice)

        case .token(let token):
            try buildForInspectTokenTransaction(amount: amount, token: token, destination: destination, referenceGasPrice: referenceGasPrice)

        default:
            throw BlockchainSdkError.failedToBuildTx
        }
    }

    func buildForSign(transaction: Transaction) throws -> Data {
        guard let suiFeeParameters = transaction.fee.parameters as? SuiFeeParameters else {
            throw BlockchainSdkError.failedToBuildTx
        }

        let signingInput: WalletCore.SuiSigningInput

        switch transaction.amount.type {
        case .coin:
            signingInput = makeCoinSigningInput(
                amount: transaction.amount.value,
                destination: transaction.destinationAddress,
                fee: suiFeeParameters
            )

        case .token(let token):
            signingInput = try makeTokenSigningInput(
                amount: transaction.amount.value,
                token: token,
                destination: transaction.destinationAddress,
                fee: suiFeeParameters
            )

        default:
            throw BlockchainSdkError.failedToBuildTx
        }

        let preImageHashes = try TransactionCompiler.preImageHashes(coinType: .sui, txInputData: signingInput.serializedData())
        let preSigningOutput = try TxCompilerPreSigningOutput(serializedData: preImageHashes)

        guard preSigningOutput.error == .ok else {
            BSDKLogger.error(error: "SuiPreSigningOutput has a error: \(preSigningOutput.errorMessage)")
            throw BlockchainSdkError.failedToBuildTx
        }

        return preSigningOutput.dataHash
    }

    func buildForSend(transaction: Transaction, signature: Data) throws -> (txBytes: String, signature: String) {
        guard let suiFeeParameters = transaction.fee.parameters as? SuiFeeParameters else {
            throw BlockchainSdkError.failedToBuildTx
        }

        let signingInput: WalletCore.SuiSigningInput

        switch transaction.amount.type {
        case .coin:
            signingInput = makeCoinSigningInput(
                amount: transaction.amount.value,
                destination: transaction.destinationAddress,
                fee: suiFeeParameters
            )

        case .token(let token):
            signingInput = try makeTokenSigningInput(
                amount: transaction.amount.value,
                token: token,
                destination: transaction.destinationAddress,
                fee: suiFeeParameters
            )

        default:
            throw BlockchainSdkError.failedToBuildTx
        }

        let compiled = try TransactionCompiler.compileWithSignaturesAndPubKeyType(
            coinType: .sui,
            txInputData: signingInput.serializedData(),
            signatures: signature.asDataVector(),
            publicKeys: publicKey.blockchainKey.asDataVector(),
            pubKeyType: .ed25519
        )

        let output = try SuiSigningOutput(serializedData: compiled)
        return (output.unsignedTx, output.signature)
    }

    func checkIfCoinGasBalanceIsNotEnoughForTokenTransaction() -> Bool {
        let coinGasBalance = coinGas?.balance ?? .zero
        return coinGasBalance < decimalValue
    }

    // MARK: - Private methods

    private func buildForInspectCoinTransaction(amount: Amount, destination: String, referenceGasPrice: Decimal) throws -> String {
        let totalAmount = coins
            .filter { $0.coinType == SuiCoinObject.CoinType.sui }
            .reduce(into: Decimal.zero) { partialResult, coin in
                partialResult += coin.balance
            }

        let decimalAmount = amount.value * decimalValue
        let isSendMax = decimalAmount == totalAmount

        let availableBudget = isSendMax ? totalAmount - Decimal(1) : totalAmount - decimalAmount
        let budget = min(availableBudget, SUIUtils.suiGasBudgetMaxValue)
        let inputAmount = isSendMax ? totalAmount - budget : decimalAmount

        let signingInput = makeCoinSigningInput(
            amount: inputAmount / decimalValue,
            destination: destination,
            fee: .init(gasPrice: referenceGasPrice, gasBudget: budget)
        )

        let compiled = try TransactionCompiler.compileWithSignatures(
            coinType: .sui,
            txInputData: signingInput.serializedData(),
            signatures: Self.signatureMock.asDataVector(),
            publicKeys: publicKey.blockchainKey.asDataVector()
        )

        return try SuiSigningOutput(serializedData: compiled).unsignedTx
    }

    private func buildForInspectTokenTransaction(amount: Amount, token: Token, destination: String, referenceGasPrice: Decimal) throws -> String {
        let availableBudget = coinGas?.balance ?? .zero
        let gasBudget = min(availableBudget, SUIUtils.suiGasBudgetMaxValue)

        let signingInput = try makeTokenSigningInput(
            amount: amount.value,
            token: token,
            destination: destination,
            fee: .init(gasPrice: referenceGasPrice, gasBudget: gasBudget)
        )

        let compiled = try TransactionCompiler.compileWithSignatures(
            coinType: .sui,
            txInputData: signingInput.serializedData(),
            signatures: Self.signatureMock.asDataVector(),
            publicKeys: publicKey.blockchainKey.asDataVector()
        )

        return try SuiSigningOutput(serializedData: compiled).unsignedTx
    }

    private func makeCoinSigningInput(amount: Decimal, destination: String, fee: SuiFeeParameters) -> WalletCore.SuiSigningInput {
        let decimalAmount = amount * decimalValue
        let coinToUse = getCoins(for: decimalAmount + fee.gasBudget, coinType: SuiCoinObject.CoinType.sui)

        return WalletCore.SuiSigningInput.with { input in
            let inputCoins = coinToUse.map { coin in
                SuiObjectRef.with { coins in
                    coins.version = coin.version
                    coins.objectID = coin.coinObjectId
                    coins.objectDigest = coin.digest
                }
            }

            input.paySui = WalletCore.SuiPaySui.with { pay in
                pay.inputCoins = inputCoins
                pay.recipients = [destination]
                pay.amounts = [decimalAmount.uint64Value]
            }

            input.signer = walletAddress
            input.gasBudget = fee.gasBudget.uint64Value
            input.referenceGasPrice = fee.gasPrice.uint64Value
        }
    }

    private func makeTokenSigningInput(
        amount: Decimal,
        token: Token,
        destination: String,
        fee: SuiFeeParameters
    ) throws -> WalletCore.SuiSigningInput {
        guard let coinGas else { throw BlockchainSdkError.failedToBuildTx }

        let decimalAmount = amount * token.decimalValue
        let coinType = try SuiCoinObject.CoinType(string: token.contractAddress)
        let coinsToUse = getCoins(for: decimalAmount, coinType: coinType)

        return WalletCore.SuiSigningInput.with { input in
            let inputCoins = coinsToUse.map { coin in
                SuiObjectRef.with {
                    $0.version = coin.version
                    $0.objectID = coin.coinObjectId
                    $0.objectDigest = coin.digest
                }
            }

            input.pay = WalletCore.SuiPay.with { pay in
                pay.inputCoins = inputCoins
                pay.recipients = [destination]
                pay.amounts = [decimalAmount.uint64Value]
                pay.gas = WalletCore.SuiObjectRef.with { gas in
                    gas.version = coinGas.version
                    gas.objectID = coinGas.coinObjectId
                    gas.objectDigest = coinGas.digest
                }
            }

            input.signer = walletAddress
            input.gasBudget = fee.gasBudget.uint64Value
            input.referenceGasPrice = fee.gasPrice.uint64Value
        }
    }

    private func getCoins(for amount: Decimal, coinType: SuiCoinObject.CoinType) -> [SuiCoinObject] {
        var suitableCoins = [SuiCoinObject]()
        var total = Decimal.zero

        for coin in coins where coin.coinType == coinType {
            suitableCoins.append(coin)
            total += coin.balance

            if total >= amount {
                break
            }
        }

        return suitableCoins
    }
}
