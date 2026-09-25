//
//  GaslessTransactionFeeMatcher.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

/// Recognizes the transfer that pays for a gasless transaction.
///
/// The relayer takes its cut as one more token transfer inside the very transaction it sponsors, so nothing in
/// the record itself marks it as a fee — only the executor method paired with the collector it pays tells it
/// from the transfer the user meant to make. Both halves are required: `send` moves tokens into Yield mode just
/// as well, and it is the collector on the other end that makes such a transfer a fee.
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
        guard isGaslessMethod(record.type) else {
            return false
        }

        return Constants.knownFeeRecipientAddresses.contains { record.hasDestination(address: $0) }
            || serviceFeeRecipientAddress.map(record.hasDestination(address:)) == true
    }

    private func isGaslessMethod(_ type: TransactionRecord.TransactionType) -> Bool {
        switch type {
        case .contractMethodIdentifier(let id):
            return smartContractMethodMapper.getName(for: id) == Constants.mappedGaslessMethodName
                || Constants.methodIds.contains { $0.caseInsensitiveCompare(id) == .orderedSame }
        case .contractMethodName(let name):
            return name == Constants.mappedGaslessMethodName
        case .transfer, .staking, .approve:
            return false
        }
    }
}

// MARK: - Constants

private extension GaslessTransactionFeeMatcher {
    enum Constants {
        static let knownFeeRecipientAddresses = [
            "0xFc719364BcCdc92D055d8C3164eF1ab4f5A9182c",
            "0xAf722F46145fbb106379d506ED3a5B96f110c8E5",
        ]

        static let methodIds = [
            "0x6234d42b",
            "0x4b072692",
            "0xf9b181bf",
            "0x0779afe6",
        ]

        static let mappedGaslessMethodName = "gaslessTransaction"
    }
}
