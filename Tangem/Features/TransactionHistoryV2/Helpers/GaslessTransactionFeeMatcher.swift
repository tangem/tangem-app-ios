//
//  GaslessTransactionFeeMatcher.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation

/// Recognizes the transfer that pays for a gasless transaction.
struct GaslessTransactionFeeMatcher {
    private let smartContractMethodMapper: SmartContractMethodMapper

    /// The collector the gasless service names at runtime, which covers one deployed after this version
    /// shipped. Kept as it arrives rather than merged into a list of addresses: the matcher is rebuilt for
    /// every record of the history, and the service answers only after the app has started.
    private let serviceFeeRecipientAddress: String?

    init(
        smartContractMethodMapper: SmartContractMethodMapper,
        serviceFeeRecipientAddress: String?
    ) {
        self.smartContractMethodMapper = smartContractMethodMapper
        self.serviceFeeRecipientAddress = serviceFeeRecipientAddress
    }

    func isNetworkFeeTransfer(_ record: TransactionRecord) -> Bool {
        if isTronCompensation(record) {
            return true
        }

        guard isGaslessMethod(record.type) else {
            return false
        }

        return record.destination.destinations.contains { isFeeRecipient($0.address.string) }
    }

    func feeTokenTransfers(of record: TransactionRecord) -> [TransactionRecord.TokenTransfer] {
        guard Self.isExecutorCall(record.type) else {
            return []
        }

        return record.tokenTransfers.filter { isFeeRecipient($0.destination) }
    }

    static func isExecutorCall(_ type: TransactionRecord.TransactionType) -> Bool {
        switch type {
        case .contractMethodIdentifier(let id):
            return Constants.executorMethodIds.contains { $0.caseInsensitiveEquals(to: id) }
        case .contractMethodName(let name):
            return name == Constants.mappedGaslessMethodName
        case .transfer, .staking, .approve:
            return false
        }
    }

    private func isGaslessMethod(_ type: TransactionRecord.TransactionType) -> Bool {
        if Self.isExecutorCall(type) {
            return true
        }

        guard case .contractMethodIdentifier(let id) = type else {
            return false
        }

        return smartContractMethodMapper.getName(for: id) == Constants.mappedGaslessMethodName
            || Constants.yieldSendMethodId.caseInsensitiveEquals(to: id)
    }

    private func isFeeRecipient(_ address: String) -> Bool {
        Constants.knownFeeRecipientAddresses.contains { $0.caseInsensitiveEquals(to: address) }
            || serviceFeeRecipientAddress?.caseInsensitiveEquals(to: address) == true
    }

    private func isTronCompensation(_ record: TransactionRecord) -> Bool {
        guard
            record.isOutgoing,
            case .transfer = record.type,
            case .single(let destination) = record.destination
        else {
            return false
        }

        return Constants.tronFeeRecipientAddresses.contains(destination.address.string)
    }
}

// MARK: - Constants

private extension GaslessTransactionFeeMatcher {
    enum Constants {
        static let knownFeeRecipientAddresses = [
            "0xFc719364BcCdc92D055d8C3164eF1ab4f5A9182c",
            "0xAf722F46145fbb106379d506ED3a5B96f110c8E5",
        ]

        static let executorMethodIds = [
            "0x6234d42b",
            "0x4b072692",
            "0xf9b181bf",
        ]

        static let yieldSendMethodId = "0x0779afe6"

        static let mappedGaslessMethodName = "gaslessTransaction"

        static let tronFeeRecipientAddresses = [
            "TSWsmaEDgWaE2VsP9tCBGh5GbBRbrdHSuZ",
        ]
    }
}
