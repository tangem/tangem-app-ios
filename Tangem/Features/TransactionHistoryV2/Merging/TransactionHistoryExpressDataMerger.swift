//
//  TransactionHistoryExpressDataMerger.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemExpress
import TangemFoundation

/// See https://app.notion.com/p/tangem/Express-36d5d34eb67880fa8082dcdb732c4364?source=copy_link#f5e12a848f494dc28b3ad32fd3243ede for details.
struct TransactionHistoryExpressDataMerger {
    // MARK: - Active statuses

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

    // MARK: - Dependencies

    private let currentToken: TokenItem
    private let isEvm: Bool
    private let isUTXO: Bool
    private let syntheticTransactionFactory: TransactionHistorySyntheticTransactionFactory

    // MARK: - Init

    init(
        ownerAddress: String,
        currentToken: TokenItem,
        feeTokenItem: TokenItem
    ) {
        self.currentToken = currentToken
        isEvm = currentToken.blockchain.isEvm
        isUTXO = currentToken.blockchain.isUTXO
        syntheticTransactionFactory = TransactionHistorySyntheticTransactionFactory(
            ownerAddress: ownerAddress,
            currentToken: currentToken,
            feeTokenItem: feeTokenItem
        )
    }

    // MARK: - Merge routine

    func merge(
        bsdkTransactions: [TransactionRecord],
        exchangeTransactions: [ExchangeTransaction],
        onrampTransactions: [OnrampTransaction]
    ) -> [TransactionRecord] {
        var bsdkTransactionsGroupedByHash: [String?: [TransactionRecord]] = bsdkTransactions.grouped(by: \.hash)
        var output: [TransactionRecord] = []
        output.reserveCapacity(bsdkTransactions.count + exchangeTransactions.count + onrampTransactions.count)
        // Tombstone-like pattern; IDs of BSDK transactions already claimed by a match
        var consumedBSDKTransactionsIds: Set<TransactionRecord.ID> = []
        // Lazily built once on first use and shared across the send / receive matchers (see their `inout` param).
        var bsdkTransactionsGroupedByDestinationAddressString: [String: [TransactionRecord]]?

        for exchangeTransaction in exchangeTransactions {
            let info = ExchangeTransactionInfo(
                transaction: exchangeTransaction,
                provider: nil // [REDACTED_TODO_COMMENT]
            )

            var didMatch = false

            // Step 1: Deterministic mapping for send/receive transactions by hashes
            var matchedBSDKTransactions = bsdkTransactionsGroupedByHash.removeValue(forKey: exchangeTransaction.payIn.hash)
                ?? bsdkTransactionsGroupedByHash.removeValue(forKey: exchangeTransaction.payOut.hash)

            // Step 2a: Heuristic mapping for send/receive transactions, performed only if no deterministic match was found
            if matchedBSDKTransactions == nil {
                let heuristicMatch = heuristicallyMatchingSendBSDKTransaction(
                    for: exchangeTransaction,
                    bsdkTransactionsGroupedByDestinationAddressString: &bsdkTransactionsGroupedByDestinationAddressString,
                    allBSDKTransactions: bsdkTransactions,
                    consumedBSDKTransactionsIds: consumedBSDKTransactionsIds
                ) ?? heuristicallyMatchingReceiveBSDKTransaction(
                    for: exchangeTransaction,
                    bsdkTransactionsGroupedByDestinationAddressString: &bsdkTransactionsGroupedByDestinationAddressString,
                    allBSDKTransactions: bsdkTransactions,
                    consumedBSDKTransactionsIds: consumedBSDKTransactionsIds
                )

                matchedBSDKTransactions = heuristicMatch.flatMap { bsdkTransactionsGroupedByHash.removeValue(forKey: $0.hash) }
            }

            if let matchedBSDKTransactions {
                output.append(contentsOf: matchedBSDKTransactions.map { $0.withExpressExtraInfo(TransactionHistoryExpressExtraInfo.exchange(info)) })
                // Updating the tombstone set to prevent double-matching of the already consumed BSDK transaction
                consumedBSDKTransactionsIds.formUnion(matchedBSDKTransactions.map(\.id))
                didMatch = true
            }

            // Step 2b: Heuristic mapping for the refund transaction.
            // This is performed regardless of whether a send/receive match was found above,
            // because the refund leg is a separate on-chain transaction that can coexist with the deposit / pay-out leg.
            if let refundMatch = heuristicallyMatchingRefundBSDKTransaction(
                for: exchangeTransaction,
                from: bsdkTransactions,
                consumedBSDKTransactionsIds: consumedBSDKTransactionsIds
            ), let refundedBSDKTransactions = bsdkTransactionsGroupedByHash.removeValue(forKey: refundMatch.hash) {
                output.append(contentsOf: refundedBSDKTransactions.map { $0.withExpressExtraInfo(TransactionHistoryExpressExtraInfo.exchange(info)) })
                // Updating the tombstone set to prevent double-matching of the already consumed BSDK transaction
                consumedBSDKTransactionsIds.formUnion(refundedBSDKTransactions.map(\.id))
                didMatch = true
            }

            // Step 3: Add a synthetic transaction only when no on-chain leg was matched.
            if !didMatch, shouldAddSyntheticTransaction(from: exchangeTransaction) {
                output.append(syntheticTransactionFactory.makeSyntheticTransaction(from: exchangeTransaction))
            }
        }

        for onrampTransaction in onrampTransactions {
            let info = OnrampTransactionInfo(
                onrampTransaction: onrampTransaction,
                provider: nil, // [REDACTED_TODO_COMMENT]
                fiatCurrency: nil // [REDACTED_TODO_COMMENT]
            )

            var didMatch = false

            // Step 1: Deterministic mapping for receive (no send for Onramp) transactions by hashes
            var matchedBSDKTransactions = bsdkTransactionsGroupedByHash.removeValue(forKey: onrampTransaction.payOut.hash)

            // Step 2: Heuristic mapping for receive (no send or refund for Onramp) transactions,
            // performed only if no deterministic match was found
            if matchedBSDKTransactions == nil {
                let heuristicMatch = heuristicallyMatchingReceiveBSDKTransaction(
                    for: onrampTransaction,
                    bsdkTransactionsGroupedByDestinationAddressString: &bsdkTransactionsGroupedByDestinationAddressString,
                    allBSDKTransactions: bsdkTransactions,
                    consumedBSDKTransactionsIds: consumedBSDKTransactionsIds
                )

                matchedBSDKTransactions = heuristicMatch.flatMap { bsdkTransactionsGroupedByHash.removeValue(forKey: $0.hash) }
            }

            if let matchedBSDKTransactions {
                output.append(contentsOf: matchedBSDKTransactions.map { $0.withExpressExtraInfo(TransactionHistoryExpressExtraInfo.onramp(info)) })
                // Updating the tombstone set to prevent double-matching of the already consumed BSDK transaction
                consumedBSDKTransactionsIds.formUnion(matchedBSDKTransactions.map(\.id))
                didMatch = true
            }

            // Step 3: Add a synthetic transaction only when no on-chain leg was matched.
            if !didMatch, shouldAddSyntheticTransaction(from: onrampTransaction) {
                output.append(syntheticTransactionFactory.makeSyntheticTransaction(from: onrampTransaction))
            }
        }

        // Adding remaining BSDK transactions that were not enriched with exchange or onramp info
        for bsdkTransactions in bsdkTransactionsGroupedByHash {
            output.append(contentsOf: bsdkTransactions.value.filter { !consumedBSDKTransactionsIds.contains($0.id) })
        }

        return sortedRecords(output)
    }

    // MARK: - Heuristic matching (Exchange)

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

        let bsdkTransactionsGroupedByDestinationAddressString = makeDestinationAddressGroupedBSDKTransactions(
            from: allBSDKTransactions,
            cache: &bsdkTransactionsGroupedByDestinationAddressString
        )

        guard let bsdkTransactionsCandidatesByReceiver = bsdkTransactionsGroupedByDestinationAddressString[
            lowerCasedAddressStringIfNeeded(exchangeTransaction.payIn.address)
        ] else {
            return nil
        }

        let amountBound = (isUTXO ? Constants.sendHeuristicAmountUTXOTolerance : Constants.sendHeuristicAmountTolerance) * targetAmount
        let normalizedFromAddress = lowerCasedAddressStringIfNeeded(exchangeTransaction.fromAddress ?? .unknown)

        return bsdkTransactionsCandidatesByReceiver
            .filter { bsdkTransaction in
                guard
                    bsdkTransaction.isOutgoing, // Only consider outgoing transactions as potential matches
                    !consumedBSDKTransactionsIds.contains(bsdkTransaction.id),
                    // The sender of the pay-in leg must be the owner
                    bsdkTransaction.sourceAddresses.contains(where: { lowerCasedAddressStringIfNeeded($0) == normalizedFromAddress })
                else {
                    return false
                }

                // Compare against the amount sent to the pay-in (deposit) address specifically (filtering UTXO change output, etc)
                let amountToPayIn = bsdkTransaction.destinationAmount(
                    to: exchangeTransaction.payIn.address,
                    addressConverter: lowerCasedAddressStringIfNeeded
                )
                return abs(amountToPayIn - targetAmount) <= amountBound
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

        let bsdkTransactionsGroupedByDestinationAddressString = makeDestinationAddressGroupedBSDKTransactions(
            from: allBSDKTransactions,
            cache: &bsdkTransactionsGroupedByDestinationAddressString
        )

        guard let bsdkTransactions = bsdkTransactionsGroupedByDestinationAddressString[
            lowerCasedAddressStringIfNeeded(exchangeTransaction.payOut.address)
        ] else {
            return nil
        }

        let targetDateRange = exchangeTransaction.createdAt ... exchangeTransaction.createdAt.advanced(by: Constants.receiveHeuristicTimeWindow)
        let normalizedFromAddress = lowerCasedAddressStringIfNeeded(exchangeTransaction.fromAddress ?? .unknown)
        let amountBound = Constants.receiveHeuristicAmountTolerance * targetAmount

        return bsdkTransactions
            .filter { bsdkTransaction in
                guard
                    !bsdkTransaction.isOutgoing, // Only consider incoming transactions as potential matches
                    !consumedBSDKTransactionsIds.contains(bsdkTransaction.id),
                    targetDateRange.contains(bsdkTransaction.normalizedDate),
                    // Exclude self-transfers (the sender must not be the user)
                    !bsdkTransaction.sourceAddresses.contains(where: { lowerCasedAddressStringIfNeeded($0) == normalizedFromAddress })
                else {
                    return false
                }

                // Compare against the amount received at the pay-out address specifically (filtering UTXO change output, etc)
                let amountToPayOut = bsdkTransaction.destinationAmount(
                    to: exchangeTransaction.payOut.address,
                    addressConverter: lowerCasedAddressStringIfNeeded
                )
                return abs(amountToPayOut - targetAmount) <= amountBound
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

    // MARK: - Heuristic matching (Onramp)

    func heuristicallyMatchingReceiveBSDKTransaction(
        for onrampTransaction: OnrampTransaction,
        // Optional and inout argument, so it will be lazily created on demand and cached for future calls to avoid O(n) * O(m) complexity
        bsdkTransactionsGroupedByDestinationAddressString: inout [String: [TransactionRecord]]?,
        allBSDKTransactions: [TransactionRecord],
        consumedBSDKTransactionsIds: Set<TransactionRecord.ID>,
    ) -> TransactionRecord? {
        guard
            onrampTransaction.to.currency == currentToken.expressCurrency.asCurrency,
            let targetAmount = onrampTransaction.to.actualAmount ?? onrampTransaction.to.amount
        else {
            return nil
        }

        // Prevents division by zero
        guard targetAmount > 0 else {
            return nil
        }

        let bsdkTransactionsGroupedByDestinationAddressString = makeDestinationAddressGroupedBSDKTransactions(
            from: allBSDKTransactions,
            cache: &bsdkTransactionsGroupedByDestinationAddressString
        )

        guard let bsdkTransactions = bsdkTransactionsGroupedByDestinationAddressString[
            lowerCasedAddressStringIfNeeded(onrampTransaction.payOut.address)
        ] else {
            return nil
        }

        let targetDateRange = onrampTransaction.createdAt ... onrampTransaction.createdAt.advanced(by: Constants.receiveHeuristicTimeWindow)
        let amountBound = Constants.receiveHeuristicAmountTolerance * targetAmount

        return bsdkTransactions
            .filter { bsdkTransaction in
                guard
                    !bsdkTransaction.isOutgoing, // Only consider incoming transactions as potential matches
                    !consumedBSDKTransactionsIds.contains(bsdkTransaction.id),
                    targetDateRange.contains(bsdkTransaction.normalizedDate)
                else {
                    return false
                }

                // Compare against the amount received at the pay-out address specifically (filtering UTXO change output, etc)
                let amountToPayOut = bsdkTransaction.destinationAmount(
                    to: onrampTransaction.payOut.address,
                    addressConverter: lowerCasedAddressStringIfNeeded
                )
                return abs(amountToPayOut - targetAmount) <= amountBound
            }
            .min(by: \.normalizedDate) // Select the earliest transaction
    }

    // MARK: - Helpers

    /// Groups BSDK transactions by their (normalized) destination address, building the grouping lazily on first
    /// use and caching it in `cache` to avoid O(n) * O(m) complexity across the send / receive matchers.
    private func makeDestinationAddressGroupedBSDKTransactions(
        from allBSDKTransactions: [TransactionRecord],
        cache: inout [String: [TransactionRecord]]?
    ) -> [String: [TransactionRecord]] {
        if let cache {
            return cache
        }

        let grouped = allBSDKTransactions.reduce(into: [String: [TransactionRecord]]()) { result, transaction in
            for destinationAddress in transaction.destinationAddresses {
                result[lowerCasedAddressStringIfNeeded(destinationAddress), default: []].append(transaction)
            }
        }
        cache = grouped

        return grouped
    }

    private func sortedRecords(_ records: [TransactionRecord]) -> [TransactionRecord] {
        return records.sorted { lhs, rhs in
            let lhsDate = lhs.date ?? .distantFuture
            let rhsDate = rhs.date ?? .distantFuture
            if lhsDate != rhsDate {
                return lhsDate > rhsDate // timestamp (date) DESC
            }

            let lhsNonce = lhs.nonce ?? -1
            let rhsNonce = rhs.nonce ?? -1
            if lhsNonce != rhsNonce {
                return lhsNonce > rhsNonce // IFNULL(nonce, -1) DESC
            }

            return lhs.hash < rhs.hash // hash ASC
        }
    }

    @inline(__always)
    private func shouldAddSyntheticTransaction(from exchangeTransaction: ExchangeTransaction) -> Bool {
        Self.activeExchangeTransactionStatuses.contains(exchangeTransaction.status)
    }

    @inline(__always)
    private func shouldAddSyntheticTransaction(from onrampTransaction: OnrampTransaction) -> Bool {
        Self.activeOnrampTransactionStatuses.contains(onrampTransaction.status)
    }

    @inline(__always)
    private func lowerCasedAddressStringIfNeeded(_ address: String) -> String {
        return isEvm ? address.lowercased() : address
    }
}

// MARK: - Constants

private extension TransactionHistoryExpressDataMerger {
    enum Constants {
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
    @inline(__always)
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
