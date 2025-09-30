//
//  YieldTransactionFeeProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import BigInt

final class YieldTransactionFeeProvider {
    private let walletAddress: String
    private let blockchain: Blockchain
    private let ethereumNetworkProvider: EthereumNetworkProvider
    private let blockaidApiService: BlockaidAPIService
    private let yieldSupplyContractAddresses: YieldSupplyContractAddresses
    private let maxNetworkFee: BigUInt

    init(
        walletAddress: String,
        blockchain: Blockchain,
        ethereumNetworkProvider: EthereumNetworkProvider,
        blockaidApiService: BlockaidAPIService,
        yieldSupplyContractAddresses: YieldSupplyContractAddresses,
        maxNetworkFee: BigUInt
    ) {
        self.walletAddress = walletAddress
        self.blockchain = blockchain
        self.ethereumNetworkProvider = ethereumNetworkProvider
        self.blockaidApiService = blockaidApiService
        self.yieldSupplyContractAddresses = yieldSupplyContractAddresses
        self.maxNetworkFee = maxNetworkFee
    }

    func deployFee(
        yieldContractAddress: String,
        tokenContractAddress: String,
    ) async throws -> DeployEnterFee {
        let transactions = deployTransactions(
            tokenContractAddress: tokenContractAddress,
            yieldContractAddress: yieldContractAddress
        )

        return try await fee(from: transactions)
    }

    func initializeFee(
        yieldContractAddress: String,
        tokenContractAddress: String
    ) async throws -> InitEnterFee {
        let transactions = initTransactions(
            tokenContractAddress: tokenContractAddress,
            yieldContractAddress: yieldContractAddress
        )

        return try await fee(from: transactions)
    }

    func reactivateFee(
        yieldContractAddress: String,
        tokenContractAddress: String,
        balance: Decimal
    ) async throws -> ReactivateEnterFee {
        let transactions = try await reactivateTransactions(
            tokenContractAddress: tokenContractAddress,
            yieldContractAddress: yieldContractAddress,
            balance: balance
        )

        return try await fee(from: transactions)
    }

    func exitFee(yieldContractAddress: String, tokenContractAddress: String) async throws -> ExitFee {
        let transactions = [
            exitTransactionData(
                yieldContractAddress: yieldContractAddress,
                tokenContractAddress: tokenContractAddress
            ),
        ]

        return try await fee(from: transactions)
    }
}

// MARK: - Transaction builders

private extension YieldTransactionFeeProvider {
    private func deployTransactions(tokenContractAddress: String, yieldContractAddress: String) -> [TransactionData] {
        var transactions = [TransactionData]()

        transactions.append(
            deployTransactionData(
                walletAddress: walletAddress,
                tokenContractAddress: tokenContractAddress
            )
        )

        transactions.append(
            approveTransactionData(
                yieldContractAddress: yieldContractAddress,
                tokenContractAddress: tokenContractAddress
            )
        )

        transactions.append(
            enterTransactionData(
                yieldContractAddress: yieldContractAddress,
                tokenContractAddress: tokenContractAddress
            )
        )

        return transactions
    }

    private func initTransactions(tokenContractAddress: String, yieldContractAddress: String) -> [TransactionData] {
        var transactions = [TransactionData]()

        transactions.append(
            initTransactionData(
                yieldContractAddress: yieldContractAddress,
                tokenContractAddress: tokenContractAddress
            )
        )

        transactions.append(
            approveTransactionData(
                yieldContractAddress: yieldContractAddress,
                tokenContractAddress: tokenContractAddress
            )
        )

        transactions.append(
            enterTransactionData(
                yieldContractAddress: yieldContractAddress,
                tokenContractAddress: tokenContractAddress
            )
        )

        return transactions
    }

    private func reactivateTransactions(
        tokenContractAddress: String,
        yieldContractAddress: String,
        balance: Decimal
    ) async throws -> [TransactionData] {
        var transactions = [TransactionData]()

        transactions.append(
            reactivateTransactionData(
                yieldContractAddress: yieldContractAddress,
                tokenContractAddress: tokenContractAddress
            )
        )

        if try await isPermissionRequired(
            yieldContractAddress: yieldContractAddress,
            tokenContractAddress: tokenContractAddress,
            balance: balance
        ) {
            transactions.append(
                approveTransactionData(
                    yieldContractAddress: yieldContractAddress,
                    tokenContractAddress: tokenContractAddress
                )
            )
        }

        transactions.append(
            enterTransactionData(
                yieldContractAddress: yieldContractAddress,
                tokenContractAddress: tokenContractAddress
            )
        )

        return transactions
    }
}

// MARK: - Fee estimation

private extension YieldTransactionFeeProvider {
    func fee<T: YieldTransactionFee>(from transactions: [TransactionData]) async throws -> T {
        let fees = try await estimateFees(
            transactions: transactions
        )

        guard fees.count == transactions.count else {
            throw YieldModuleError.feeNotFound
        }

        return try T(fees: fees)
    }

    func estimateFees(transactions: [TransactionData]) async throws -> [Fee] {
        let defaultGasLimit = BigUInt(Constants.estimatedGasLimit)
        // we can calculate exact fee when transaction in one
        if transactions.count == 1, let transaction = transactions.first {
            let fees = try await ethereumNetworkProvider.getFee(
                destination: transaction.to,
                value: Constants.zeroCoinAmount,
                data: transaction.data
            ).async()

            let fee = try fees.normalFee()

            return [fee]
        }
        do {
            // estimate gas limits with Blockaid
            let gasLimits = try await blockaidGasLimits(transactions: transactions)
            return try await getFees(gasLimits: gasLimits)
        } catch {
            // fallback to hardcoded gas limit
            return try await getFees(gasLimits: [BigUInt](repeating: defaultGasLimit, count: transactions.count))
        }
    }

    func blockaidGasLimits(transactions: [TransactionData]) async throws -> [BigUInt] {
        let result = try await blockaidApiService.scanEvmTransactionBulk(
            blockchain: blockchain,
            transactions: transactions.map { transaction in
                .init(
                    from: walletAddress,
                    to: transaction.to,
                    data: transaction.data.hexString.addHexPrefix(),
                    value: Constants.zeroCoinAmount
                )
            }
        )

        let gasLimits = result.map {
            BigUInt(Data(hexString: $0.gasEstimation.estimate))
        }

        guard gasLimits.count == transactions.count else {
            throw YieldModuleError.feeNotFound
        }

        return gasLimits
    }

    func getFees(gasLimits: [BigUInt]) async throws -> [Fee] {
        try await withThrowingTaskGroup(of: [Fee].self) { [blockchain, ethereumNetworkProvider] group in
            for gasLimit in gasLimits {
                group.addTask {
                    let parameters = try await ethereumNetworkProvider.getFee(
                        gasLimit: gasLimit,
                        supportsEIP1559: blockchain.supportsEIP1559
                    )

                    let feeValue = parameters.calculateFee(decimalValue: blockchain.decimalValue)
                    let gasAmount = Amount(with: blockchain, value: feeValue)

                    return [Fee(gasAmount, parameters: parameters)]
                }
            }

            var fees = [Fee]()
            for try await result in group {
                let fee = try result.normalFee()
                fees.append(fee)
            }

            return fees
        }
    }
}

// MARK: - Transaction data builders

private extension YieldTransactionFeeProvider {
    private func deployTransactionData(
        walletAddress: String,
        tokenContractAddress: String
    ) -> TransactionData {
        let yieldModuleAddressMethod = DeployYieldModuleMethod(
            walletAddress: walletAddress,
            tokenContractAddress: tokenContractAddress,
            maxNetworkFee: maxNetworkFee
        )

        return TransactionData(
            to: yieldSupplyContractAddresses.factoryContractAddress,
            data: yieldModuleAddressMethod.data
        )
    }

    private func initTransactionData(
        yieldContractAddress: String,
        tokenContractAddress: String,
    ) -> TransactionData {
        let approveMethod = InitYieldTokenMethod(
            tokenContractAddress: tokenContractAddress,
            maxNetworkFee: maxNetworkFee
        )

        return TransactionData(
            to: yieldContractAddress,
            data: approveMethod.data
        )
    }

    private func reactivateTransactionData(
        yieldContractAddress: String,
        tokenContractAddress: String,
    ) -> TransactionData {
        let approveMethod = ReactivateTokenMethod(
            tokenContractAddress: tokenContractAddress,
            maxNetworkFee: maxNetworkFee
        )

        return TransactionData(
            to: yieldContractAddress,
            data: approveMethod.data
        )
    }

    private func approveTransactionData(
        yieldContractAddress: String,
        tokenContractAddress: String,
    ) -> TransactionData {
        let approveMethod = ApproveERC20TokenMethod(
            spender: yieldContractAddress,
            amount: EthereumUtils.mapToBigUInt(.greatestFiniteMagnitude)
        )

        return TransactionData(
            to: tokenContractAddress,
            data: approveMethod.data
        )
    }

    private func enterTransactionData(
        yieldContractAddress: String,
        tokenContractAddress: String
    ) -> TransactionData {
        let enterMethod = EnterProtocolMethod(tokenContractAddress: tokenContractAddress)

        return TransactionData(
            to: yieldContractAddress,
            data: enterMethod.data
        )
    }

    private func exitTransactionData(
        yieldContractAddress: String,
        tokenContractAddress: String
    ) -> TransactionData {
        let exitMethod = WithdrawAndDeactivateMethod(tokenContractAddress: tokenContractAddress)

        return TransactionData(
            to: yieldContractAddress,
            data: exitMethod.data
        )
    }
}

// MARK: - Permission check

private extension YieldTransactionFeeProvider {
    private func isPermissionRequired(
        yieldContractAddress: String,
        tokenContractAddress: String,
        balance: Decimal
    ) async throws -> Bool {
        let allowanceString = try await ethereumNetworkProvider.getAllowanceRaw(
            owner: walletAddress,
            spender: yieldContractAddress,
            contractAddress: tokenContractAddress
        ).async()

        let allowance = BigUInt(allowanceString) ?? 0

        return allowance < Constants.maxAllowance
    }
}

// MARK: - Auxiliary types

private extension YieldTransactionFeeProvider {
    struct TransactionData {
        let to: String
        let data: Data
    }
}

// MARK: - Helper

private extension Array where Element == Fee {
    func normalFee() throws -> Fee {
        guard let lastFee = last else {
            throw YieldModuleError.feeNotFound
        }

        return self[safe: 1] ?? lastFee
    }
}

extension YieldTransactionFeeProvider {
    enum Constants {
        static let zeroCoinAmount = "0x0"
        static let maxAllowance = BigUInt(2).power(256) - 1
        static let estimatedGasLimit = 500_000 // gas units, provided by dbaturin
    }
}
