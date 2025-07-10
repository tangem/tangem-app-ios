//
//  WCFeeProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import BigInt
import TangemFoundation

protocol WCFeeProvider {
    func getFee(for transaction: WalletConnectEthTransaction, walletModel: any WalletModel) -> AnyPublisher<[Fee], Error>
}

final class CommonWCFeeProvider: WCFeeProvider {
    func getFee(for transaction: WalletConnectEthTransaction, walletModel: any WalletModel) -> AnyPublisher<[Fee], Error> {
        return Future { promise in
            do {
                let fees = try self.createFeesFromTransaction(transaction, walletModel: walletModel)
                promise(.success(fees))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }

    private func createFeesFromTransaction(_ transaction: WalletConnectEthTransaction, walletModel: any WalletModel) throws -> [Fee] {
        let blockchain = walletModel.tokenItem.blockchain

        guard blockchain.isEvm else {
            throw WCFeeProviderError.unsupportedBlockchain
        }

        if walletModel.isDemo {
            return createDemoFees(blockchain: blockchain)
        }

        let gasLimit = getGasLimit(from: transaction, blockchain: blockchain)

        if let gasPriceString = transaction.gasPrice {
            return try createFeesFromGasPrice(
                gasLimit: gasLimit,
                gasPriceString: gasPriceString,
                blockchain: blockchain
            )
        }

        return try createFallbackFees(gasLimit: gasLimit, blockchain: blockchain, walletModel: walletModel)
    }

    private func getGasLimit(from transaction: WalletConnectEthTransaction, blockchain: Blockchain) -> BigUInt {
        if let gasString = transaction.gas ?? transaction.gasLimit {
            if let gasValue = BigUInt(gasString.removeHexPrefix(), radix: 16) {
                if case .mantle = blockchain {
                    return MantleUtils.multiplyGasLimit(Int(gasValue), with: MantleUtils.feeGasLimitMultiplier)
                }
                return gasValue
            }
        }

        return BigUInt(21000)
    }

    private func createFeesFromGasPrice(
        gasLimit: BigUInt,
        gasPriceString: String,
        blockchain: Blockchain
    ) throws -> [Fee] {
        guard let gasPrice = BigUInt(gasPriceString.removeHexPrefix(), radix: 16) else {
            throw WCFeeProviderError.unsupportedBlockchain
        }
        if blockchain.supportsEIP1559 {
            let slowFee = createEIP1559Fee(
                gasLimit: gasLimit,
                maxFeePerGas: BigUInt(Double(gasPrice) * 0.8),
                priorityFee: BigUInt(Double(gasPrice) * 0.1),
                blockchain: blockchain
            )

            let marketFee = createEIP1559Fee(
                gasLimit: gasLimit,
                maxFeePerGas: gasPrice,
                priorityFee: BigUInt(Double(gasPrice) * 0.1),
                blockchain: blockchain
            )

            let fastFee = createEIP1559Fee(
                gasLimit: gasLimit,
                maxFeePerGas: BigUInt(Double(gasPrice) * 1.2),
                priorityFee: BigUInt(Double(gasPrice) * 0.15),
                blockchain: blockchain
            )

            return [slowFee, marketFee, fastFee]
        } else {
            let slowFee = createLegacyFee(
                gasLimit: gasLimit,
                gasPrice: BigUInt(Double(gasPrice) * 0.8),
                blockchain: blockchain
            )

            let marketFee = createLegacyFee(
                gasLimit: gasLimit,
                gasPrice: gasPrice,
                blockchain: blockchain
            )

            let fastFee = createLegacyFee(
                gasLimit: gasLimit,
                gasPrice: BigUInt(Double(gasPrice) * 1.2),
                blockchain: blockchain
            )

            return [slowFee, marketFee, fastFee]
        }
    }

    private func createFallbackFees(gasLimit: BigUInt, blockchain: Blockchain, walletModel: any WalletModel) throws -> [Fee] {
        if blockchain.supportsEIP1559 {
            let baseMaxFeePerGas = BigUInt(20 * 1_000_000_000) // 20 Gwei
            let basePriorityFee = BigUInt(2 * 1_000_000_000) // 2 Gwei

            let slowFee = createEIP1559Fee(
                gasLimit: gasLimit,
                maxFeePerGas: BigUInt(Double(baseMaxFeePerGas) * 0.8),
                priorityFee: BigUInt(Double(basePriorityFee) * 0.8),
                blockchain: blockchain
            )

            let marketFee = createEIP1559Fee(
                gasLimit: gasLimit,
                maxFeePerGas: baseMaxFeePerGas,
                priorityFee: basePriorityFee,
                blockchain: blockchain
            )

            let fastFee = createEIP1559Fee(
                gasLimit: gasLimit,
                maxFeePerGas: BigUInt(Double(baseMaxFeePerGas) * 1.3),
                priorityFee: BigUInt(Double(basePriorityFee) * 1.3),
                blockchain: blockchain
            )

            return [slowFee, marketFee, fastFee]
        } else {
            let baseGasPrice = BigUInt(20 * 1_000_000_000)

            let slowFee = createLegacyFee(
                gasLimit: gasLimit,
                gasPrice: BigUInt(Double(baseGasPrice) * 0.8),
                blockchain: blockchain
            )

            let marketFee = createLegacyFee(
                gasLimit: gasLimit,
                gasPrice: baseGasPrice,
                blockchain: blockchain
            )

            let fastFee = createLegacyFee(
                gasLimit: gasLimit,
                gasPrice: BigUInt(Double(baseGasPrice) * 1.3),
                blockchain: blockchain
            )

            return [slowFee, marketFee, fastFee]
        }
    }

    private func createEIP1559Fee(gasLimit: BigUInt, maxFeePerGas: BigUInt, priorityFee: BigUInt, blockchain: Blockchain) -> Fee {
        let parameters = EthereumEIP1559FeeParameters(
            gasLimit: gasLimit,
            maxFeePerGas: maxFeePerGas,
            priorityFee: priorityFee
        )

        let feeValue = parameters.calculateFee(decimalValue: blockchain.decimalValue)
        let amount = Amount(with: blockchain, value: feeValue)

        return Fee(amount, parameters: parameters)
    }

    private func createLegacyFee(gasLimit: BigUInt, gasPrice: BigUInt, blockchain: Blockchain) -> Fee {
        let parameters = EthereumLegacyFeeParameters(
            gasLimit: gasLimit,
            gasPrice: gasPrice
        )

        let feeValue = parameters.calculateFee(decimalValue: blockchain.decimalValue)
        let amount = Amount(with: blockchain, value: feeValue)

        return Fee(amount, parameters: parameters)
    }

    private func createDemoFees(blockchain: Blockchain) -> [Fee] {
        let demoValues: [Decimal] = [0.001, 0.002, 0.003] // ETH

        return demoValues.map { value in
            let amount = Amount(with: blockchain, value: value)
            return Fee(amount)
        }
    }
}

enum WCFeeProviderError: Error {
    case unsupportedBlockchain
}
