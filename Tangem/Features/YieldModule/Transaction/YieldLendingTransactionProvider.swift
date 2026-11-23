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

enum YieldLendingTransactionProvider {
    static func preparationCall(
        _ preparation: LendingDepositPreparation,
        owner: String,
        yieldModule: String,
        wrappedNative: String,
        factory: String
    ) -> (destination: String, data: Data) {
        switch preparation {
        case .deployModule:
            let method = DeployYieldModuleMethod(walletAddress: owner, tokenContractAddress: wrappedNative, maxNetworkFee: maxNetworkFee)
            return (factory, method.data)
        case .initializeToken(let upgradeImplementation):
            let method = InitYieldTokenMethod(tokenContractAddress: wrappedNative, maxNetworkFee: maxNetworkFee)
            return (yieldModule, moduleCallData(method: method, upgradeImplementation: upgradeImplementation))
        case .reactivateToken(let upgradeImplementation):
            let method = ReactivateTokenMethod(tokenContractAddress: wrappedNative, maxNetworkFee: maxNetworkFee)
            return (yieldModule, moduleCallData(method: method, upgradeImplementation: upgradeImplementation))
        }
    }

    static func depositCallData(upgradeImplementation: String?) -> Data {
        moduleCallData(method: EnterProtocolByOwnerWithNativeMethod(), upgradeImplementation: upgradeImplementation)
    }

    static func withdrawCallData(
        _ amount: WithdrawalAmount,
        blockchain: Blockchain,
        upgradeImplementation: String?
    ) throws -> Data {
        try moduleCallData(method: withdrawMethod(amount, blockchain: blockchain), upgradeImplementation: upgradeImplementation)
    }

    private static func positiveWholeWei(_ amount: Decimal, blockchain: Blockchain) throws -> Decimal {
        let wei = amount.rounded(scale: blockchain.decimalCount, roundingMode: .down)

        guard wei > 0 else {
            throw ValidationError.invalidAmount
        }

        return wei
    }

    private static func withdrawMethod(_ amount: WithdrawalAmount, blockchain: Blockchain) throws -> SmartContractMethod {
        switch amount {
        case .all:
            return WithdrawAndDeactivateNativeMethod()
        case .partial(let value):
            let wei = try positiveWholeWei(value, blockchain: blockchain)

            guard let weiValue = Amount(with: blockchain, type: .coin, value: wei).bigUIntValue else {
                throw ValidationError.invalidAmount
            }

            return WithdrawNativeMethod(amount: weiValue)
        }
    }

    private static func moduleCallData(method: SmartContractMethod, upgradeImplementation: String?) -> Data {
        upgradeImplementation.map {
            UpgradeToAndCallMethod(newImplementation: $0, callData: method.data).data
        } ?? method.data
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
