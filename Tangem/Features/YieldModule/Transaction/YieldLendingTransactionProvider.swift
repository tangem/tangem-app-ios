//
//  YieldLendingTransactionProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import BlockchainSdk
import TangemFoundation

final class YieldLendingTransactionProvider {
    private let blockchain: Blockchain
    private let factoryContractAddress: String
    private let transactionCreator: TransactionCreator

    init(blockchain: Blockchain, factoryContractAddress: String, transactionCreator: TransactionCreator) {
        self.blockchain = blockchain
        self.factoryContractAddress = factoryContractAddress
        self.transactionCreator = transactionCreator
    }

    func deployTransaction(owner: String, wrappedNative: String, fee: Fee) async throws -> Transaction {
        let method = DeployYieldModuleMethod(
            walletAddress: owner,
            tokenContractAddress: wrappedNative,
            maxNetworkFee: Self.maxNetworkFee
        )

        return try await transaction(value: .zero, contractAddress: factoryContractAddress, data: method.data, fee: fee)
    }

    func initTokenTransaction(
        wrappedNative: String,
        yieldModule: String,
        upgradeImplementation: String?,
        fee: Fee
    ) async throws -> Transaction {
        try await moduleTransaction(
            value: .zero,
            yieldModule: yieldModule,
            method: InitYieldTokenMethod(tokenContractAddress: wrappedNative, maxNetworkFee: Self.maxNetworkFee),
            upgradeImplementation: upgradeImplementation,
            fee: fee
        )
    }

    func reactivateTokenTransaction(
        wrappedNative: String,
        yieldModule: String,
        upgradeImplementation: String?,
        fee: Fee
    ) async throws -> Transaction {
        try await moduleTransaction(
            value: .zero,
            yieldModule: yieldModule,
            method: ReactivateTokenMethod(tokenContractAddress: wrappedNative, maxNetworkFee: Self.maxNetworkFee),
            upgradeImplementation: upgradeImplementation,
            fee: fee
        )
    }

    static func depositCallData(upgradeImplementation: String?) -> Data {
        moduleCallData(method: EnterProtocolByOwnerWithNativeMethod(), upgradeImplementation: upgradeImplementation)
    }

    func withdrawTransaction(
        _ amount: WithdrawalAmount,
        yieldModule: String,
        upgradeImplementation: String?,
        fee: Fee
    ) async throws -> Transaction {
        try await moduleTransaction(
            value: .zero,
            yieldModule: yieldModule,
            method: withdrawMethod(amount),
            upgradeImplementation: upgradeImplementation,
            fee: fee
        )
    }

    private func positiveWholeWei(_ amount: Decimal) throws -> Decimal {
        let wei = amount.rounded(scale: blockchain.decimalCount, roundingMode: .down)

        guard wei > 0 else {
            throw ValidationError.invalidAmount
        }

        return wei
    }

    private func withdrawMethod(_ amount: WithdrawalAmount) throws -> SmartContractMethod {
        switch amount {
        case .all:
            return WithdrawAndDeactivateNativeMethod()
        case .partial(let value):
            let wei = try positiveWholeWei(value)

            guard let weiValue = Amount(with: blockchain, type: .coin, value: wei).bigUIntValue else {
                throw ValidationError.invalidAmount
            }

            return WithdrawNativeMethod(amount: weiValue)
        }
    }

    private func moduleTransaction(
        value: Decimal,
        yieldModule: String,
        method: SmartContractMethod,
        upgradeImplementation: String?,
        fee: Fee
    ) async throws -> Transaction {
        let data = Self.moduleCallData(method: method, upgradeImplementation: upgradeImplementation)
        return try await transaction(value: value, contractAddress: yieldModule, data: data, fee: fee)
    }

    private static func moduleCallData(method: SmartContractMethod, upgradeImplementation: String?) -> Data {
        upgradeImplementation.map {
            UpgradeToAndCallMethod(newImplementation: $0, callData: method.data).data
        } ?? method.data
    }

    private func transaction(value: Decimal, contractAddress: String, data: Data, fee: Fee) async throws -> Transaction {
        try await transactionCreator.createTransaction(
            amount: Amount(with: blockchain, type: .coin, value: value),
            fee: fee,
            destinationAddress: contractAddress,
            contractAddress: contractAddress,
            params: EthereumTransactionParams(data: data)
        )
    }
}

// MARK: - WithdrawalAmount

extension YieldLendingTransactionProvider {
    enum WithdrawalAmount: Equatable {
        case all
        case partial(Decimal)
    }
}

private extension YieldLendingTransactionProvider {
    static let maxNetworkFee: BigUInt = .zero
}
