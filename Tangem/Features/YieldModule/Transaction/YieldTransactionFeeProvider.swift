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
    private let allowanceChecker: AllowanceChecker
    private let yieldSupplyContractAddresses: YieldSupplyContractAddresses
    private let maxNetworkFee: BigUInt

    init(
        walletAddress: String,
        blockchain: Blockchain,
        ethereumNetworkProvider: EthereumNetworkProvider,
        allowanceChecker: AllowanceChecker,
        yieldSupplyContractAddresses: YieldSupplyContractAddresses,
        maxNetworkFee: BigUInt
    ) {
        self.walletAddress = walletAddress
        self.blockchain = blockchain
        self.ethereumNetworkProvider = ethereumNetworkProvider
        self.allowanceChecker = allowanceChecker
        self.yieldSupplyContractAddresses = yieldSupplyContractAddresses
        self.maxNetworkFee = maxNetworkFee
    }

    func deployFee(walletAddress: String, tokenContractAddress: String) async throws -> DeployEnterFee {
        let yieldModuleAddressMethod = DeployYieldModuleMethod(
            walletAddress: walletAddress,
            tokenContractAddress: tokenContractAddress,
            maxNetworkFee: maxNetworkFee
        )

        async let yieldModuleAddressMethodFee = estimateFee(
            contractAddress: yieldSupplyContractAddresses.factoryContractAddress,
            transactionData: yieldModuleAddressMethod.data
        )

        async let estimatedFee = estimateFee(gasLimit: YieldConstants.estimatedGasLimit)

        return try await DeployEnterFee(
            deployFee: yieldModuleAddressMethodFee,
            approveFee: estimatedFee,
            enterFee: estimatedFee
        )
    }

    func initializeFee(
        yieldContractAddress: String,
        tokenContractAddress: String,
        balance: Decimal
    ) async throws -> InitEnterFee {
        async let estimatedFee = estimateFee(gasLimit: YieldConstants.estimatedGasLimit)
        let approveData = try await approveData(
            spender: yieldContractAddress,
            tokenContractAddress: tokenContractAddress,
            balance: balance
        )

        return try await InitEnterFee(
            initFee: estimatedFee,
            enterFee: EnterFee(enterFee: estimatedFee, approveFee: approveData?.fee)
        )
    }

    func reactivateFee(
        yieldContractAddress: String,
        tokenContractAddress: String,
        balance: Decimal
    ) async throws -> ReactivateEnterFee {
        async let estimatedFee = estimateFee(gasLimit: YieldConstants.estimatedGasLimit)
        async let approveData = approveData(
            spender: yieldContractAddress,
            tokenContractAddress: tokenContractAddress,
            balance: balance
        )

        return try await ReactivateEnterFee(
            reactivateFee: estimatedFee,
            enterFee: EnterFee(enterFee: estimatedFee, approveFee: approveData?.fee)
        )
    }

    func enterFee(
        yieldContractAddress: String,
        tokenContractAddress: String,
        balance: Decimal
    ) async throws -> EnterFee {
        async let estimatedFee = estimateFee(gasLimit: YieldConstants.estimatedGasLimit)
        async let approveData = approveData(
            spender: yieldContractAddress,
            tokenContractAddress: tokenContractAddress,
            balance: balance
        )

        return try await EnterFee(enterFee: estimatedFee, approveFee: approveData?.fee)
    }

    func exitFee(yieldContractAddress: String, tokenContractAddress: String) async throws -> any YieldTransactionFee {
        let method = WithdrawAndDeactivateMethod(tokenContractAddress: tokenContractAddress)

        let fee = try await estimateFee(
            contractAddress: yieldContractAddress,
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
            throw YieldModuleError.feeNotFound
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

    private func approveData(
        spender: String,
        tokenContractAddress: String,
        balance: Decimal
    ) async throws -> ApproveTransactionData? {
        let allowanceString = try await ethereumNetworkProvider.getAllowanceRaw(
            owner: walletAddress,
            spender: spender,
            contractAddress: tokenContractAddress
        ).async()

        let allowance = BigUInt(allowanceString) ?? 0

        guard allowance < Constants.maxAllowance else {
            return nil
        }

        return try await allowanceChecker.makeApproveData(
            spender: spender,
            amount: .greatestFiniteMagnitude,
            policy: .unlimited
        )
    }
}

extension YieldTransactionFeeProvider {
    enum Constants {
        static let maxAllowance = BigUInt(2).power(256) - 1
    }
}
