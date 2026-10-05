//
//  TransactionHistoryTransferClassifier.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

/// Tells the transfers a transaction is made of apart: the ones that take part in the merge, and the ones that
/// must not — the gasless fee and the legs of a Yield contract. Both are recognized on their own terms, a swap
/// only by what Express reports about the whole transaction, so leaving them in would let the swap claim them
/// as its content.
struct TransactionHistoryTransferClassifier {
    private let smartContractMethodMapper: SmartContractMethodMapper
    private let gaslessFeeMatcher: GaslessTransactionFeeMatcher

    init(
        smartContractMethodMapper: SmartContractMethodMapper,
        gaslessFeeMatcher: GaslessTransactionFeeMatcher
    ) {
        self.smartContractMethodMapper = smartContractMethodMapper
        self.gaslessFeeMatcher = gaslessFeeMatcher
    }

    func classify(
        _ records: [TransactionRecord]
    ) -> (standalone: [TransactionRecord], mergeable: [TransactionRecord], gaslessFees: [TransactionRecord]) {
        var standalone: [TransactionRecord] = []
        var mergeable: [TransactionRecord] = []
        var gaslessFees: [TransactionRecord] = []

        for record in records {
            if gaslessFeeMatcher.isNetworkFeeTransfer(record) {
                gaslessFees.append(record)
            } else if record.isFromYieldContract || isYieldModeSwitch(record) {
                standalone.append(record)
            } else {
                mergeable.append(record)
            }
        }

        return (standalone: standalone, mergeable: mergeable, gaslessFees: gaslessFees)
    }

    private func isYieldModeSwitch(_ record: TransactionRecord) -> Bool {
        switch record.type {
        case .contractMethodIdentifier(let id):
            return isYieldModeSwitch(methodName: smartContractMethodMapper.getName(for: id))
                || Constants.yieldModeSwitchMethodIds.contains { $0.caseInsensitiveCompare(id) == .orderedSame }
        case .contractMethodName(let name):
            return isYieldModeSwitch(methodName: name)
        case .transfer, .staking, .approve:
            return false
        }
    }

    private func isYieldModeSwitch(methodName: String?) -> Bool {
        methodName.map(Constants.yieldModeSwitchMethodNames.contains) ?? false
    }
}

// MARK: - Constants

private extension TransactionHistoryTransferClassifier {
    enum Constants {
        static let yieldModeSwitchMethodIds = [
            "0x79be55f7",
            "0xc65e6dcf",
        ]

        static let yieldModeSwitchMethodNames = [
            "yieldEnter",
            "yieldWithdraw",
        ]
    }
}
