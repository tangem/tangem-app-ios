//
//  _TransactionHistoryDataMerger.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemExpress
import TangemFoundation

// [REDACTED_TODO_COMMENT]
/// See https://app.notion.com/p/tangem/Express-36d5d34eb67880fa8082dcdb732c4364?source=copy_link#f5e12a848f494dc28b3ad32fd3243ede for details.
struct _TransactionHistoryDataMerger {
    private let ownerAddress: String
    private let currentToken: TokenItem
    private let feeTokenItem: TokenItem
    private let isEvm: Bool
    private let isUTXO: Bool

    private static let activeExchangeTransactionStatuses: Set<ExpressTransactionStatus> = [
        .preview,
        .created,
        .unknown,
        .exchangeTxSent,
        .waiting,
        .waitingTxHash,
        .confirming,
        .exchanging,
        .sending,
        .verifying,
        .failed,
    ]

    private static let activeOnrampTransactionStatuses: Set<OnrampTransactionStatus> = [
        .created,
        .waitingForPayment,
        .paymentProcessing,
        .verifying,
        .paid,
        .sending,
    ]

    init(
        ownerAddress: String,
        currentToken: TokenItem,
        feeTokenItem: TokenItem
    ) {
        self.ownerAddress = ownerAddress
        self.currentToken = currentToken
        self.feeTokenItem = feeTokenItem
        isEvm = currentToken.blockchain.isEvm
        isUTXO = currentToken.blockchain.isUTXO
    }

    func heuristicallyMatchingSendBSDKTransaction(
        for exchangeTransaction: ExchangeTransaction,
        // Optional and inout argument, so it will be lazily created on demand and cached for future calls to avoid O(n) * O(m) complexity
        bsdkTransactionsGroupedByDestinationAddressString: inout [String: [TransactionRecord]]?,
        allBSDKTransactions: [TransactionRecord],
        consumedBSDKTransactionsIds: Set<TransactionRecord.ID>,
    ) -> TransactionRecord? {
        guard exchangeTransaction.from.currency == currentToken.expressCurrency.asCurrency else {
            return nil
        }

        let targetAmount = exchangeTransaction.from.actualAmount ?? exchangeTransaction.from.amount

        // Prevents division by zero
        guard targetAmount > 0 else {
            return nil
        }

        var _bsdkTransactionsGroupedByDestinationAddressString: [String: [TransactionRecord]]
        if let bsdkTransactionsGroupedByDestinationAddressString {
            // Re-use the cached grouping if it was already created in a previous call to this function
            _bsdkTransactionsGroupedByDestinationAddressString = bsdkTransactionsGroupedByDestinationAddressString
        } else {
            // Lazily create the grouping of BSDK transactions by destination address string to avoid O(n) * O(m) complexity
            _bsdkTransactionsGroupedByDestinationAddressString = allBSDKTransactions.reduce(into: [:]) { result, transaction in
                for destinationAddress in transaction.destinationAddresses {
                    result[lowerCasedAddressStringIfNeeded(destinationAddress), default: []].append(transaction)
                }
            }
            bsdkTransactionsGroupedByDestinationAddressString = _bsdkTransactionsGroupedByDestinationAddressString
        }

        guard let bsdkTransactionsCandidatesByReceiver = _bsdkTransactionsGroupedByDestinationAddressString[
            lowerCasedAddressStringIfNeeded(exchangeTransaction.payIn.address)
        ] else {
            return nil
        }

        let amountBound = (isUTXO ? Constants.sendHeuristicAmountUTXOTolerance : Constants.sendHeuristicAmountTolerance) * targetAmount
        let normalizedFromAddress = lowerCasedAddressStringIfNeeded(exchangeTransaction.fromAddress ?? .unknown)

        return bsdkTransactionsCandidatesByReceiver
            .filter { bsdkTransaction in
                // Compare against the amount sent to the pay-in (deposit) address specifically (filtering UTXO change output, etc)
                let amountToPayIn = bsdkTransaction.destinationAmount(
                    to: exchangeTransaction.payIn.address,
                    addressConverter: lowerCasedAddressStringIfNeeded
                )
                return bsdkTransaction.isOutgoing // Only consider outgoing transactions as potential matches
                    && !consumedBSDKTransactionsIds.contains(bsdkTransaction.id)
                    // The sender of the pay-in leg must be the owner
                    && bsdkTransaction.sourceAddresses.contains { lowerCasedAddressStringIfNeeded($0) == normalizedFromAddress }
                    && abs(amountToPayIn - targetAmount) <= amountBound
            }
            .min(by: \.normalizedDate) // Select the earliest transaction
    }

    func heuristicallyMatchingRefundBSDKTransaction(
        for exchangeTransaction: ExchangeTransaction,
        from bsdkTransactions: [TransactionRecord],
        consumedBSDKTransactionsIds: Set<TransactionRecord.ID>,
    ) -> TransactionRecord? {
        guard
            exchangeTransaction.status == .refunded,
            exchangeTransaction.refund?.currency == currentToken.expressCurrency.asCurrency
        else {
            return nil
        }

        let targetAmount = exchangeTransaction.from.actualAmount ?? exchangeTransaction.from.amount

        // Prevents division by zero
        guard targetAmount > 0 else {
            return nil
        }

        let targetDateRange = exchangeTransaction.createdAt ... exchangeTransaction.updatedAt.advanced(by: Constants.refundHeuristicTimeWindow)
        let amountBound = Constants.refundHeuristicAmountTolerance * targetAmount

        return bsdkTransactions
            .filter { bsdkTransaction in
                return !bsdkTransaction.isOutgoing // Only consider incoming transactions as potential refunds
                    && !consumedBSDKTransactionsIds.contains(bsdkTransaction.id)
                    && abs(bsdkTransaction.destinationAmountValue - targetAmount) <= amountBound
                    && targetDateRange.contains(bsdkTransaction.normalizedDate)
            }
            .min(by: \.normalizedDate) // Select the earliest transaction
    }

    func heuristicallyMatchingReceiveBSDKTransaction(
        for exchangeTransaction: ExchangeTransaction,
        // Optional and inout argument, so it will be lazily created on demand and cached for future calls to avoid O(n) * O(m) complexity
        bsdkTransactionsGroupedByDestinationAddressString: inout [String: [TransactionRecord]]?,
        allBSDKTransactions: [TransactionRecord],
        consumedBSDKTransactionsIds: Set<TransactionRecord.ID>,
    ) -> TransactionRecord? {
        guard
            exchangeTransaction.status != .refunded,
            exchangeTransaction.to.currency == currentToken.expressCurrency.asCurrency
        else {
            return nil
        }

        let targetAmount = exchangeTransaction.to.actualAmount ?? exchangeTransaction.to.amount

        // Prevents division by zero
        guard targetAmount > 0 else {
            return nil
        }

        var _bsdkTransactionsGroupedByDestinationAddressString: [String: [TransactionRecord]]
        if let bsdkTransactionsGroupedByDestinationAddressString {
            // Re-use the cached grouping if it was already created in a previous call to this function
            _bsdkTransactionsGroupedByDestinationAddressString = bsdkTransactionsGroupedByDestinationAddressString
        } else {
            // Lazily create the grouping of BSDK transactions by destination address string to avoid O(n) * O(m) complexity
            _bsdkTransactionsGroupedByDestinationAddressString = allBSDKTransactions.reduce(into: [:]) { result, transaction in
                for destinationAddress in transaction.destinationAddresses {
                    result[lowerCasedAddressStringIfNeeded(destinationAddress), default: []].append(transaction)
                }
            }
            bsdkTransactionsGroupedByDestinationAddressString = _bsdkTransactionsGroupedByDestinationAddressString
        }

        guard let bsdkTransactions = _bsdkTransactionsGroupedByDestinationAddressString[
            lowerCasedAddressStringIfNeeded(exchangeTransaction.payOut.address)
        ] else {
            return nil
        }

        let targetDateRange = exchangeTransaction.createdAt ... exchangeTransaction.updatedAt.advanced(by: Constants.receiveHeuristicTimeWindow)
        let normalizedFromAddress = lowerCasedAddressStringIfNeeded(exchangeTransaction.fromAddress ?? .unknown)
        let amountBound = Constants.receiveHeuristicAmountTolerance * targetAmount

        return bsdkTransactions
            .filter { bsdkTransaction in
                // Compare against the amount received at the pay-out address specifically (filtering UTXO change output, etc)
                let amountToPayOut = bsdkTransaction.destinationAmount(
                    to: exchangeTransaction.payOut.address,
                    addressConverter: lowerCasedAddressStringIfNeeded
                )
                return !bsdkTransaction.isOutgoing // Only consider incoming transactions as potential matches
                    && !consumedBSDKTransactionsIds.contains(bsdkTransaction.id)
                    // Exclude self-transfers (the sender must not be the user)
                    && !bsdkTransaction.sourceAddresses.contains { lowerCasedAddressStringIfNeeded($0) == normalizedFromAddress }
                    && abs(amountToPayOut - targetAmount) <= amountBound
                    && targetDateRange.contains(bsdkTransaction.normalizedDate)
            }
            .min(by: \.normalizedDate) // Select the earliest transaction
    }

    func merge(
        bsdkTransactions: [TransactionRecord],
        exchangeTransactions: [ExchangeTransaction],
        onrampTransactions: [OnrampTransaction]
    ) -> [TransactionRecord] {
        var bsdkTransactionsGroupedByHash: [String?: [TransactionRecord]] = bsdkTransactions.grouped(by: \.hash)
        var output: [TransactionRecord] = []
        // Tombstone-like pattern; IDs of BSDK transactions already claimed by a match
        var consumedBSDKTransactionsIds: Set<TransactionRecord.ID> = []

        for exchangeTransaction in exchangeTransactions {
            // Step 1: Deterministic mapping
            if let bsdkTransactions = bsdkTransactionsGroupedByHash.removeValue(forKey: exchangeTransaction.payIn.hash)
                ?? bsdkTransactionsGroupedByHash.removeValue(forKey: exchangeTransaction.payOut.hash) {
                let info = ExchangeTransactionInfo(
                    transaction: exchangeTransaction,
                    provider: nil // [REDACTED_TODO_COMMENT]
                )
                output.append(contentsOf: bsdkTransactions.map { $0.withExtraInfo(.exchange(info)) })
                consumedBSDKTransactionsIds.formUnion(bsdkTransactions.map(\.id))
                continue
            }

            // Step 2: Heuristic mapping
            // [REDACTED_TODO_COMMENT]

            // Step 3: Add synthetic transaction if needed
            if shouldAddSyntheticTransaction(from: exchangeTransaction) {
                output.append(makeSyntheticTransaction(from: exchangeTransaction))
            }
        }

        for onrampTransaction in onrampTransactions {
            // Step 1: Deterministic mapping
            if let bsdkTransactions = bsdkTransactionsGroupedByHash.removeValue(forKey: onrampTransaction.payOut.hash) {
                let info = OnrampTransactionInfo(
                    onrampTransaction: onrampTransaction,
                    provider: nil, // [REDACTED_TODO_COMMENT]
                    fiatCurrency: nil // [REDACTED_TODO_COMMENT]
                )
                output.append(contentsOf: bsdkTransactions.map { $0.withExtraInfo(.onramp(info)) })
                consumedBSDKTransactionsIds.formUnion(bsdkTransactions.map(\.id))
                continue
            }

            // Step 2: Heuristic mapping
            // [REDACTED_TODO_COMMENT]

            // Step 3: Add synthetic transaction if needed
            if shouldAddSyntheticTransaction(from: onrampTransaction) {
                output.append(makeSyntheticTransaction(from: onrampTransaction))
            }
        }

        // Adding remaining BSDK transactions that were not enriched with exchange or onramp info
        for bsdkTransactions in bsdkTransactionsGroupedByHash {
            output.append(contentsOf: bsdkTransactions.value.filter { !consumedBSDKTransactionsIds.contains($0.id) })
        }

        // [REDACTED_TODO_COMMENT]
        return output
    }

    private func shouldAddSyntheticTransaction(from exchangeTransaction: ExchangeTransaction) -> Bool {
        Self.activeExchangeTransactionStatuses.contains(exchangeTransaction.status)
    }

    private func shouldAddSyntheticTransaction(from onrampTransaction: OnrampTransaction) -> Bool {
        Self.activeOnrampTransactionStatuses.contains(onrampTransaction.status)
    }

    private func makeSyntheticTransaction(from exchangeTransaction: ExchangeTransaction) -> TransactionRecord {
        let info = ExchangeTransactionInfo(
            transaction: exchangeTransaction,
            provider: nil // [REDACTED_TODO_COMMENT]
        )
        let outgoing = isOutgoing(exchangeTransaction)
        let source: TransactionRecord.SourceType
        let destination: TransactionRecord.DestinationType
        let hash: String

        if outgoing {
            // Pay-in leg: the wallet sends the `from` asset to the provider deposit address.
            let amount = exchangeTransaction.from.actualAmount ?? exchangeTransaction.from.amount
            source = .single(.init(address: exchangeTransaction.fromAddress ?? .unknown, amount: amount))
            destination = .single(.init(address: .user(exchangeTransaction.payIn.address), amount: amount))
            hash = exchangeTransaction.payIn.hash ?? exchangeTransaction.txId
        } else {
            // Pay-out leg: the wallet receives the `to` asset at its payout address.
            let amount = exchangeTransaction.to.actualAmount ?? exchangeTransaction.to.amount
            source = .single(.init(address: .unknown, amount: amount)) // The source address of the pay-out leg is unknown at this point
            destination = .single(.init(address: .user(exchangeTransaction.payOut.address), amount: amount))
            hash = exchangeTransaction.payOut.hash ?? exchangeTransaction.txId
        }

        return TransactionRecord(
            hash: hash,
            index: 0, // A single transaction record, therefore index is always 0
            source: source,
            destination: destination,
            fee: feeTokenItem.zeroFee, // Unknown at this point
            status: syntheticTransactionStatus(from: exchangeTransaction.status),
            isOutgoing: outgoing,
            type: .contractMethodName(name: Constants.swapMethodName),
            date: exchangeTransaction.createdAt,
            tokenTransfers: [], // No inner token transfers for exchange transactions because no such information is provided by the API
            extraInfo: TransactionRecord.TransactionRecordExtraInfo.exchange(info)
        )
    }

    private func makeSyntheticTransaction(from onrampTransaction: OnrampTransaction) -> TransactionRecord {
        // Onramp only has a pay-out leg (fiat -> crypto), so the wallet always receives.
        let amount = onrampTransaction.to.actualAmount ?? onrampTransaction.to.amount ?? 0
        let info = OnrampTransactionInfo(
            onrampTransaction: onrampTransaction,
            provider: nil, // [REDACTED_TODO_COMMENT]
            fiatCurrency: nil // [REDACTED_TODO_COMMENT]
        )

        return TransactionRecord(
            hash: onrampTransaction.payOut.hash ?? onrampTransaction.txId,
            index: 0, // A single transaction record, therefore index is always 0
            source: .single(.init(address: .unknown, amount: amount)), // The source address of the pay-out leg is unknown at this point
            destination: .single(.init(address: .user(onrampTransaction.payOut.address), amount: amount)),
            fee: feeTokenItem.zeroFee, // Unknown at this point
            status: syntheticTransactionStatus(from: onrampTransaction.status),
            isOutgoing: false, // Onramp transactions are always incoming by definition (fiat -> crypto)
            type: .contractMethodName(name: Constants.onrampMethodName),
            date: onrampTransaction.createdAt,
            tokenTransfers: [], // No inner token transfers for onramp transactions by definition
            extraInfo: TransactionRecord.TransactionRecordExtraInfo.onramp(info)
        )
    }

    @inline(__always)
    private func isOutgoing(_ exchangeTransaction: ExchangeTransaction) -> Bool {
        // Fast path: using the owner address to determine the direction
        let isOnSendLeg = exchangeTransaction.fromAddress.map { ownerAddress.caseInsensitiveEquals(to: $0) } ?? false
        let isOnReceiveLeg = ownerAddress.caseInsensitiveEquals(to: exchangeTransaction.payOut.address)

        if isOnSendLeg != isOnReceiveLeg {
            return isOnSendLeg
        }

        // Slow path: the address is ambiguous (owner on both or neither leg, e.g. a swap sent to self),
        // using current token to determine the direction
        return currentToken.expressCurrency.asCurrency == exchangeTransaction.from.currency
    }

    @inline(__always)
    private func lowerCasedAddressStringIfNeeded(_ address: String) -> String {
        return isEvm ? address.lowercased() : address
    }

    private func syntheticTransactionStatus(from status: ExpressTransactionStatus) -> TransactionRecord.TransactionStatus {
        switch status {
        case .finished,
             .refunded:
            return .confirmed
        case .failed,
             .txFailed:
            return .failed
        case .unknown,
             .preview,
             .created,
             .exchangeTxSent,
             .waiting,
             .waitingTxHash,
             .expired,
             .confirming,
             .exchanging,
             .sending,
             .verifying,
             .paused:
            return .unconfirmed
        }
    }

    private func syntheticTransactionStatus(from status: OnrampTransactionStatus) -> TransactionRecord.TransactionStatus {
        switch status {
        case .finished,
             .refunded:
            return .confirmed
        case .failed:
            return .failed
        case .unknown,
             .created,
             .expired,
             .waitingForPayment,
             .paymentProcessing,
             .verifying,
             .paid,
             .sending,
             .refunding,
             .paused:
            return .unconfirmed
        }
    }
}

// MARK: - Constants

private extension _TransactionHistoryDataMerger {
    enum Constants {
        static let swapMethodName = "swap"
        static let onrampMethodName = "onramp"
        static let sendHeuristicAmountTolerance = Decimal(Double.ulpOfOne)
        /// 0.1% tolerance for amount differences to account for UTXO change outputs.
        static let sendHeuristicAmountUTXOTolerance = Decimal(stringValue: "0.001")!
        /// 1 day.
        static let refundHeuristicTimeWindow: TimeInterval = 60 * 60 * 24
        /// 15% tolerance for amount differences to account for multiple UTXO outputs w/o address filtration.
        static let refundHeuristicAmountTolerance = Decimal(stringValue: "0.15")!
        /// 1 day.
        static let receiveHeuristicTimeWindow: TimeInterval = 60 * 60 * 24
        /// 5% tolerance for amount differences to account for multiple UTXO outputs with address filtration.
        static let receiveHeuristicAmountTolerance = Decimal(stringValue: "0.05")!
    }
}

// MARK: - Convenience extensions

private extension TransactionRecord {
    var normalizedDate: Date {
        date ?? .distantPast
    }

    var destinationAmountValue: Decimal {
        destination.destinations.reduce(0) { $0 + $1.amount }
    }

    func destinationAmount(
        to address: String,
        addressConverter: (_ address: String) -> String
    ) -> Decimal {
        let targetAddress = addressConverter(address)

        return destination.destinations.reduce(into: Decimal.zero) { sum, destination in
            if addressConverter(destination.address.string) == targetAddress {
                sum += destination.amount
            }
        }
    }

    var sourceAddresses: [String] {
        source.sources.map(\.address)
    }

    var destinationAddresses: [String] {
        destination.destinations.map(\.address.string)
    }
}
