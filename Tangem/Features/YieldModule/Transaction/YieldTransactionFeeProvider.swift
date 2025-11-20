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
    private let tokenBalanceProvider: TokenBalanceProvider

    init(
        walletAddress: String,
        blockchain: Blockchain,
        ethereumNetworkProvider: EthereumNetworkProvider,
        blockaidApiService: BlockaidAPIService,
        yieldSupplyContractAddresses: YieldSupplyContractAddresses,
        tokenBalanceProvider: TokenBalanceProvider
    ) {
        self.walletAddress = walletAddress
        self.blockchain = blockchain
        self.ethereumNetworkProvider = ethereumNetworkProvider
        self.blockaidApiService = blockaidApiService
        self.yieldSupplyContractAddresses = yieldSupplyContractAddresses
        self.tokenBalanceProvider = tokenBalanceProvider
    }

    func deployFee(
        yieldContractAddress: String,
        tokenContractAddress: String,
        maxNetworkFee: BigUInt
    ) async throws -> DeployEnterFee {
        let transactions = deployTransactions(
            tokenContractAddress: tokenContractAddress,
            yieldContractAddress: yieldContractAddress,
            maxNetworkFee: maxNetworkFee
        )

        let fees = try await fees(from: transactions)

        return try DeployEnterFee(fees: fees)
    }

    func initializeFee(
        yieldContractAddress: String,
        tokenContractAddress: String,
        maxNetworkFee: BigUInt
    ) async throws -> InitEnterFee {
        let transactions = initTransactions(
            tokenContractAddress: tokenContractAddress,
            yieldContractAddress: yieldContractAddress,
            maxNetworkFee: maxNetworkFee
        )

        let fees = try await fees(from: transactions)

        return try InitEnterFee(fees: fees)
    }

    func reactivateFee(
        yieldContractAddress: String,
        tokenContractAddress: String,
        tokenDecimalCount: Int,
        maxNetworkFee: BigUInt
    ) async throws -> ReactivateEnterFee {
        var transactions = [TransactionData]()

        transactions.append(
            reactivateTransactionData(
                yieldContractAddress: yieldContractAddress,
                tokenContractAddress: tokenContractAddress,
                maxNetworkFee: maxNetworkFee
            )
        )

        let isPermissionRequired = try await isPermissionRequired(
            yieldContractAddress: yieldContractAddress,
            tokenContractAddress: tokenContractAddress,
            tokenDecimalCount: tokenDecimalCount
        )

        if isPermissionRequired {
            transactions.append(
                approveTransactionData(
                    yieldContractAddress: yieldContractAddress,
                    tokenContractAddress: tokenContractAddress
                )
            )
        }

        if isEnterTransactionAvailable {
            transactions.append(
                enterTransactionData(
                    yieldContractAddress: yieldContractAddress,
                    tokenContractAddress: tokenContractAddress
                )
            )
        }

        let fees = try await fees(from: transactions)

        return try ReactivateEnterFee(
            fees: fees,
            isEnterAvailable: isEnterTransactionAvailable,
            isPermissionRequired: isPermissionRequired
        )
    }

    func exitFee(yieldContractAddress: String, tokenContractAddress: String) async throws -> ExitFee {
        let transactions = [
            exitTransactionData(
                yieldContractAddress: yieldContractAddress,
                tokenContractAddress: tokenContractAddress
            ),
        ]

        let fees = try await fees(from: transactions)
        return try ExitFee(fees: fees)
    }

    func approveFee(yieldContractAddress: String, tokenContractAddress: String) async throws -> ApproveFee {
        let transactions = [
            approveTransactionData(
                yieldContractAddress: yieldContractAddress,
                tokenContractAddress: tokenContractAddress
            ),
        ]

        let fees = try await fees(from: transactions)
        return try ApproveFee(fees: fees)
    }

    func currentNetworkFeeParameters() async throws -> EthereumFeeParameters {
        try await ethereumNetworkProvider.getFee(
            gasLimit: Constants.minimalTopUpGasLimit,
            supportsEIP1559: blockchain.supportsEIP1559
        )
    }
}

// MARK: - Transaction builders

private extension YieldTransactionFeeProvider {
    private func deployTransactions(
        tokenContractAddress: String,
        yieldContractAddress: String,
        maxNetworkFee: BigUInt
    ) -> [TransactionData] {
        var transactions = [TransactionData]()

        transactions.append(
            deployTransactionData(
                walletAddress: walletAddress,
                tokenContractAddress: tokenContractAddress,
                maxNetworkFee: maxNetworkFee
            )
        )

        transactions.append(
            approveTransactionData(
                yieldContractAddress: yieldContractAddress,
                tokenContractAddress: tokenContractAddress
            )
        )

        if isEnterTransactionAvailable {
            transactions.append(
                enterTransactionData(
                    yieldContractAddress: yieldContractAddress,
                    tokenContractAddress: tokenContractAddress
                )
            )
        }

        return transactions
    }

    private func initTransactions(
        tokenContractAddress: String,
        yieldContractAddress: String,
        maxNetworkFee: BigUInt,
    ) -> [TransactionData] {
        var transactions = [TransactionData]()

        transactions.append(
            initTransactionData(
                yieldContractAddress: yieldContractAddress,
                tokenContractAddress: tokenContractAddress,
                maxNetworkFee: maxNetworkFee
            )
        )

        transactions.append(
            approveTransactionData(
                yieldContractAddress: yieldContractAddress,
                tokenContractAddress: tokenContractAddress
            )
        )

        if isEnterTransactionAvailable {
            transactions.append(
                enterTransactionData(
                    yieldContractAddress: yieldContractAddress,
                    tokenContractAddress: tokenContractAddress
                )
            )
        }

        return transactions
    }
}

// MARK: - Fee estimation

private extension YieldTransactionFeeProvider {
    func fees(from transactions: [TransactionData]) async throws -> [Fee] {
        let fees = try await estimateFees(
            transactions: transactions
        )

        guard fees.count == transactions.count else {
            throw YieldModuleError.feeNotFound
        }

        return fees.map {
            $0.increasingGasLimit(
                byPercents: EthereumFeeParametersConstants.yieldModuleGasLimitIncreasePercent,
                blockchain: blockchain,
                decimalValue: blockchain.decimalValue
            )
        }
    }

    func estimateFees(transactions: [TransactionData]) async throws -> [Fee] {
        let defaultGasLimit = BigUInt(Constants.estimatedGasLimit)
        // we can calculate exact fee when transaction in one
        if let transaction = transactions.singleElement {
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

        let gasLimits = try result.map {
            guard let result = EthereumUtils.sanitizeAndParseToBigUInt($0.gasEstimation.estimate) else {
                throw YieldModuleError.unableToParseData
            }
            return result
        }

        guard gasLimits.count == transactions.count else {
            throw YieldModuleError.feeNotFound
        }

        return gasLimits
    }

    func getFees(gasLimits: [BigUInt]) async throws -> [Fee] {
        let feeParameters = try await ethereumNetworkProvider.getFees(
            gasLimits: gasLimits,
            supportsEIP1559: blockchain.supportsEIP1559
        )

        return feeParameters.map { params in
            let feeValue = params.calculateFee(decimalValue: blockchain.decimalValue)
            let gasAmount = Amount(with: blockchain, value: feeValue)

            return Fee(gasAmount, parameters: params)
        }
    }
}

// MARK: - Transaction data builders

private extension YieldTransactionFeeProvider {
    private func deployTransactionData(
        walletAddress: String,
        tokenContractAddress: String,
        maxNetworkFee: BigUInt,
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
        maxNetworkFee: BigUInt,
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
        maxNetworkFee: BigUInt,
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
        tokenDecimalCount: Int
    ) async throws -> Bool {
        let allowanceString = try await ethereumNetworkProvider.getAllowanceRaw(
            owner: walletAddress,
            spender: yieldContractAddress,
            contractAddress: tokenContractAddress
        ).async()

        return YieldAllowanceUtil().isPermissionRequired(allowance: allowanceString)
    }

    var isEnterTransactionAvailable: Bool {
        (tokenBalanceProvider.balanceType.value ?? .zero) > 0
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
        static let estimatedGasLimit = 500_000 // gas units, provided by dbaturin
        static let minimalTopUpGasLimit: BigUInt = 350_000
        static let minimalTopUpBuffer: Decimal = 1.25
        static let minimalTopUpFeeLimit: Decimal = 0.04
    }
}
