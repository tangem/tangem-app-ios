//
//  CommonWalletConnectEthTransactionBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import BigInt

protocol WalletConnectEthTransactionBuilder {
    func buildTx(from transaction: WalletConnectEthTransaction, for walletModel: WalletModel) async throws -> Transaction
}

struct CommonWalletConnectEthTransactionBuilder {
    private func getGasPrice(for tx: WalletConnectEthTransaction, using gasLoader: EthereumGasLoader) async throws -> Int {
        if let gasPrice = tx.gasPrice?.hexToInteger {
            return gasPrice
        }

        let price = try await gasLoader.getGasPrice().async()
        return Int(price)
    }

    private func getGasLimit(for tx: WalletConnectEthTransaction, with amount: Amount, using gasLoader: EthereumGasLoader) async throws -> Int {
        if let dappGasLimit = tx.gas?.hexToInteger ?? tx.gasLimit?.hexToInteger {
            return dappGasLimit
        }

        let gasLimitBigInt = try await gasLoader.getGasLimit(
            to: tx.to,
            from: tx.from,
            value: tx.value,
            data: tx.data
        ).async()
        return Int(gasLimitBigInt)
    }
}

extension CommonWalletConnectEthTransactionBuilder: WalletConnectEthTransactionBuilder {
    func buildTx(from wcTransaction: WalletConnectEthTransaction, for walletModel: WalletModel) async throws -> Transaction {
        guard let gasLoader = walletModel.walletManager as? EthereumGasLoader else {
            let error = WalletConnectV2Error.missingGasLoader
            AppLog.shared.error(error)
            throw error
        }

        let blockchain = walletModel.wallet.blockchain
        let rawValue = wcTransaction.value ?? "0x0"
        guard let value = EthereumUtils.parseEthereumDecimal(rawValue, decimalsCount: blockchain.decimalCount) else {
            let error = ETHError.failedToParseBalance(value: rawValue, address: "", decimals: blockchain.decimalCount)
            AppLog.shared.error(error)
            throw error
        }

        let valueAmount = Amount(with: blockchain, type: .coin, value: value)

        async let walletUpdate = walletModel.$state
            .setFailureType(to: Error.self)
            .tryMap { state -> WalletModel.State in
                switch state {
                case .failed(let error):
                    throw error
                case .noAccount(let message):
                    throw message
                default:
                    return state
                }
            }
            .filter { $0 == .idle }
            .eraseToAnyPublisher()
            .async()
        async let gasPrice = getGasPrice(for: wcTransaction, using: gasLoader)
        async let gasLimit = getGasLimit(for: wcTransaction, with: valueAmount, using: gasLoader)

        walletModel.update(silent: false)

        let feeValue = try await Decimal(gasLimit * gasPrice) / blockchain.decimalValue
        let gasAmount = Amount(with: blockchain, value: feeValue)
        let feeParameters = try await EthereumFeeParameters(gasLimit: BigUInt(gasLimit), gasPrice: BigUInt(gasPrice))
        let fee = Fee(gasAmount, parameters: feeParameters)

        let _ = try await walletUpdate

        var transaction = try walletModel.walletManager.createTransaction(
            amount: valueAmount,
            fee: fee,
            sourceAddress: wcTransaction.from,
            destinationAddress: wcTransaction.to
        )

        let contractDataString = wcTransaction.data.drop0xPrefix
        let wcTxData = Data(hexString: String(contractDataString))

        transaction.params = EthereumTransactionParams(
            data: wcTxData,
            nonce: wcTransaction.nonce?.hexToInteger
        )

        return transaction
    }
}
