//
//  YieldLendingTransactionProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation

final class YieldLendingTransactionProvider {
    private let blockchain: Blockchain
    private let transactionCreator: TransactionCreator

    init(blockchain: Blockchain, transactionCreator: TransactionCreator) {
        self.blockchain = blockchain
        self.transactionCreator = transactionCreator
    }

    func depositTransaction(amount: Decimal, yieldModule: String, fee: Fee) async throws -> Transaction {
        try await transaction(
            value: positiveWholeWei(amount),
            yieldModule: yieldModule,
            method: EnterProtocolByOwnerWithNativeMethod(),
            fee: fee
        )
    }

    func withdrawTransaction(_ amount: WithdrawalAmount, yieldModule: String, fee: Fee) async throws -> Transaction {
        try await transaction(value: .zero, yieldModule: yieldModule, method: withdrawMethod(amount), fee: fee)
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

    private func transaction(value: Decimal, yieldModule: String, method: SmartContractMethod, fee: Fee) async throws -> Transaction {
        try await transactionCreator.createTransaction(
            amount: Amount(with: blockchain, type: .coin, value: value),
            fee: fee,
            destinationAddress: yieldModule,
            contractAddress: yieldModule,
            params: EthereumTransactionParams(data: method.data)
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
