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
    private let blockchain: Blockchain
    private let ethereumNetworkProvider: EthereumNetworkProvider
    private let allowanceChecker: AllowanceChecker

    init(blockchain: Blockchain, ethereumNetworkProvider: EthereumNetworkProvider, allowanceChecker: AllowanceChecker) {
        self.blockchain = blockchain
        self.ethereumNetworkProvider = ethereumNetworkProvider
        self.allowanceChecker = allowanceChecker
    }

    func deployFee(address: String, contractAddress: String) async throws -> DeployEnterFee {
        let yieldModuleAddressMethod = DeployYieldModuleMethod(
            sourceAddress: address,
            tokenAddress: contractAddress,
            maxNetworkFee: BigUInt(decimal: YieldConstants.maxNetworkFee * blockchain.decimalValue)!
        )

        async let yieldModuleAddressMethodFee = estimateFee(
            contractAddress: YieldConstants.yieldModuleFactoryContractAddress,
            transactionData: yieldModuleAddressMethod.data
        )

        async let estimatedFee = estimateFee(gasLimit: YieldConstants.estimatedGasLimit)

        return try await DeployEnterFee(
            deployFee: yieldModuleAddressMethodFee,
            approveFee: estimatedFee,
            enterFee: estimatedFee
        )
    }

    func initializeFee(address: String, yieldModule: String, balance: Decimal) async throws -> InitEnterFee {
        async let estimatedFee = estimateFee(gasLimit: YieldConstants.estimatedGasLimit)
        let approveData = try await approveData(spender: yieldModule, balance: balance)

        return try await InitEnterFee(
            initFee: estimatedFee,
            enterFee: EnterFee(enterFee: estimatedFee, approveFee: approveData?.fee)
        )
    }

    func reactivateFee(address: String, yieldModule: String, balance: Decimal) async throws -> ReactivateEnterFee {
        async let estimatedFee = estimateFee(gasLimit: YieldConstants.estimatedGasLimit)
        async let approveData = approveData(spender: yieldModule, balance: balance)

        return try await ReactivateEnterFee(
            reactivateFee: estimatedFee,
            enterFee: EnterFee(enterFee: estimatedFee, approveFee: approveData?.fee)
        )
    }

    func enterFee(address: String, yieldModule: String, balance: Decimal) async throws -> EnterFee {
        async let estimatedFee = estimateFee(gasLimit: YieldConstants.estimatedGasLimit)
        async let approveData = approveData(spender: yieldModule, balance: balance)

        return try await EnterFee(enterFee: estimatedFee, approveFee: approveData?.fee)
    }

    func exitFee(yieldModule: String, contractAddress: String) async throws -> any YieldTransactionFee {
        let method = WithdrawAndDeactivateMethod(yieldTokenAddress: contractAddress)

        let fee = try await estimateFee(
            contractAddress: yieldModule,
            transactionData: method.data
        )

        return ExitFee(fee: fee)
    }
}

private extension YieldTransactionFeeProvider {
    private func estimateFee(contractAddress: String, transactionData: Data) async throws -> Fee {
        let amount = Amount(with: blockchain, type: .coin, value: 0)

        let fees = try await ethereumNetworkProvider.getFee(
            destination: contractAddress,
            value: amount.encodedForSend,
            data: transactionData
        ).async()

        guard let fee = fees.last else {
            throw YieldServiceError.feeNotFound
        }

        return fee
    }

    private func estimateFee(gasLimit: Int) async throws -> Fee {
        let parameters = try await ethereumNetworkProvider.getFee(
            gasLimit: BigUInt(gasLimit),
            supportsEIP1559: blockchain.supportsEIP1559
        )

        let feeValue = parameters.calculateFee(decimalValue: blockchain.decimalValue)
        let gasAmount = Amount(with: blockchain, value: feeValue)

        return Fee(gasAmount, parameters: parameters)
    }

    private func approveData(spender: String, balance: Decimal) async throws -> ApproveTransactionData? {
        let balance = balance > 0 ? balance : 1
        let isPermissionRequired = try await allowanceChecker.isPermissionRequired(
            amount: balance * blockchain.decimalValue,
            spender: spender
        )

        guard isPermissionRequired else {
            return nil
        }

        return try await allowanceChecker.makeApproveData(
            spender: spender,
            amount: .greatestFiniteMagnitude,
            policy: .unlimited
        )
    }
}
