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
    @Injected(\.transactionHistoryAuxDataRepository) private var auxDataRepository: TransactionHistoryAuxDataRepository
    @Injected(\.smartContractMethodMapper) private var smartContractMethodMapper: SmartContractMethodMapper

    // MARK: - Dependencies

    private let normalizedCurrentCurrency: ExpressCurrency
    private let walletModelAddresses: Set<String>
    private let isEvm: Bool
    private let isUTXO: Bool
    private let syntheticTransactionFactory: TransactionHistorySyntheticTransactionFactory

    // MARK: - Init

    init(
        walletModelAddresses: [String],
        currentToken: TokenItem,
        feeTokenItem: TokenItem
    ) {
        let isEvm = currentToken.blockchain.isEvm
        normalizedCurrentCurrency = currentToken.normalizedExpressCurrency
        self.isEvm = isEvm
        isUTXO = currentToken.blockchain.isUTXO

        self.walletModelAddresses = walletModelAddresses
            .map { TransactionHistoryAddressNormalizer.normalize($0, isEvm: isEvm) }
            .toSet()

        syntheticTransactionFactory = TransactionHistorySyntheticTransactionFactory(
            walletModelAddresses: walletModelAddresses,
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
            let provider = auxDataRepository.provider(id: exchangeTransaction.providerId, branch: .swap)
            let cryptoCurrencies = auxDataRepository.cryptoCurrencies(for: exchangeTransaction.expressCurrencies)
            let info = ExchangeTransactionInfo(
                transaction: exchangeTransaction,
                provider: provider,
                cryptoCurrencies: cryptoCurrencies
            )
            var didMatch = false

            // Step 1: Mapping for send/receive transactions by the hashes the deal reports. Finding the
            // transaction is exact; telling the deal's own records apart from the rest of that transaction
            // isn't, and is left to `claimLegRecords`
            var matchedBSDKTransactions = claimLegRecords(
                forHash: exchangeTransaction.payIn.hash,
                of: exchangeTransaction,
                from: &bsdkTransactionsGroupedByHash
            ) ?? claimLegRecords(
                forHash: exchangeTransaction.payOut.hash,
                of: exchangeTransaction,
                from: &bsdkTransactionsGroupedByHash
            )

            // Step 2a: Heuristic mapping for send/receive transactions, performed only if no hash match was found
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

                matchedBSDKTransactions = heuristicMatch.flatMap {
                    claimLegRecords(forHash: $0.hash, of: exchangeTransaction, from: &bsdkTransactionsGroupedByHash)
                }
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
            let provider = auxDataRepository.provider(id: onrampTransaction.providerId, branch: .onramp)
            let fiatCurrency = auxDataRepository.fiatCurrency(for: onrampTransaction.from)
            let cryptoCurrencies = auxDataRepository.cryptoCurrencies(for: onrampTransaction.expressCurrencies)
            let info = OnrampTransactionInfo(
                transaction: onrampTransaction,
                provider: provider,
                fiatCurrency: fiatCurrency,
                cryptoCurrencies: cryptoCurrencies
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

        let transferCollapser = TransactionHistoryTransferCollapser(
            walletModelAddresses: walletModelAddresses,
            isEvm: isEvm,
            smartContractMethodMapper: smartContractMethodMapper
        )

        return sortedRecords(transferCollapser.collapse(output))
    }

    // MARK: - Leg claiming (Exchange)

    /// One on-chain transaction can carry transfers that belong to no deal at all — the fee transfer of a
    /// gasless transaction, for one — and, when both legs of a swap live on the same blockchain, its pay-in
    /// transaction shows up in the history of the token being bought as well. Claiming the whole group by its
    /// hash would mark all of that as a swap, so what isn't the leg is passed through unenriched, keeping its
    /// own classification, while the leg that has no on-chain record of its own is covered by a synthetic
    /// transaction.
    ///
    /// Returns `nil` when the group holds no record of the expected leg, which is the same as no match at all.
    private func claimLegRecords(
        forHash hash: String?,
        of exchangeTransaction: ExchangeTransaction,
        from bsdkTransactionsGroupedByHash: inout [String?: [TransactionRecord]]
    ) -> [TransactionRecord]? {
        guard let records = bsdkTransactionsGroupedByHash.removeValue(forKey: hash) else {
            return nil
        }

        let (claimedRecords, unclaimedRecords) = legRecords(from: records, of: exchangeTransaction)

        guard let claimedRecords = claimedRecords.nilIfEmpty else {
            bsdkTransactionsGroupedByHash[hash] = records
            return nil
        }

        if let unclaimedRecords = unclaimedRecords.nilIfEmpty {
            bsdkTransactionsGroupedByHash[hash] = unclaimedRecords
        }

        return claimedRecords
    }

    private func legRecords(
        from records: [TransactionRecord],
        of exchangeTransaction: ExchangeTransaction
    ) -> (claimed: [TransactionRecord], unclaimed: [TransactionRecord]) {
        guard let leg = expressLeg(of: exchangeTransaction) else {
            return (claimed: records, unclaimed: [])
        }

        let rule = legRule(for: leg, of: exchangeTransaction)
        let (sameDirectionRecords, oppositeDirectionRecords) = records.partitioned { $0.isOutgoing == rule.isOutgoing }

        guard rule.targetAmount > 0 else {
            return (claimed: sameDirectionRecords, unclaimed: oppositeDirectionRecords)
        }

        let (recordsPayingTheLegAddress, rest) = sameDirectionRecords.partitioned {
            rule.matches(amount: $0.destinationAmount(to: rule.address, addressConverter: lowerCasedAddressStringIfNeeded))
        }

        if let claimed = recordsPayingTheLegAddress.nilIfEmpty {
            return (claimed: claimed, unclaimed: oppositeDirectionRecords + rest)
        }

        let (recordsTransferringTheAmount, remainder) = sameDirectionRecords.partitioned { rule.matches(amount: $0.destinationAmountValue) }

        if let claimed = recordsTransferringTheAmount.nilIfEmpty {
            return (claimed: claimed, unclaimed: oppositeDirectionRecords + remainder)
        }

        // The deal named this hash itself, so its records stay the leg even when none of them carries the
        // reported amount — a DEX splitting the deal between pools, a partial fill, a rounded amount
        return (claimed: sameDirectionRecords, unclaimed: oppositeDirectionRecords)
    }

    private func expressLeg(of exchangeTransaction: ExchangeTransaction) -> ExpressLeg? {
        switch (
            exchangeTransaction.from.currency == normalizedCurrentCurrency,
            exchangeTransaction.to.currency == normalizedCurrentCurrency
        ) {
        case (true, false):
            return .payIn
        case (false, true):
            return .payOut
        case (true, true), (false, false):
            return nil
        }
    }

    private func legRule(for leg: ExpressLeg, of exchangeTransaction: ExchangeTransaction) -> ExpressLegRule {
        switch leg {
        case .payIn:
            return ExpressLegRule(
                isOutgoing: true,
                address: exchangeTransaction.payIn.address,
                targetAmount: exchangeTransaction.from.normalizedAmount,
                amountTolerance: isUTXO ? Constants.sendHeuristicAmountUTXOTolerance : Constants.sendHeuristicAmountTolerance
            )
        case .payOut:
            return ExpressLegRule(
                isOutgoing: false,
                address: exchangeTransaction.payOut.address,
                targetAmount: exchangeTransaction.to.normalizedAmount,
                amountTolerance: Constants.receiveHeuristicAmountTolerance
            )
        }
    }

    private func legAmount(of bsdkTransaction: TransactionRecord, rule: ExpressLegRule) -> Decimal {
        let amountToLeg = bsdkTransaction.destinationAmount(
            to: rule.address,
            addressConverter: lowerCasedAddressStringIfNeeded
        )

        return amountToLeg > 0 ? amountToLeg : bsdkTransaction.destinationAmountValue
    }

    // MARK: - Heuristic matching (Exchange)

    func heuristicallyMatchingSendBSDKTransaction(
        for exchangeTransaction: ExchangeTransaction,
        // Optional and inout argument, so it will be lazily created on demand and cached for future calls to avoid O(n) * O(m) complexity
        bsdkTransactionsGroupedByDestinationAddressString: inout [String: [TransactionRecord]]?,
        allBSDKTransactions: [TransactionRecord],
        consumedBSDKTransactionsIds: Set<TransactionRecord.ID>
    ) -> TransactionRecord? {
        guard exchangeTransaction.from.currency == normalizedCurrentCurrency else {
            return nil
        }

        let rule = legRule(for: .payIn, of: exchangeTransaction)

        // Prevents division by zero
        guard rule.targetAmount > 0 else {
            return nil
        }

        let bsdkTransactionsGroupedByDestinationAddressString = makeDestinationAddressGroupedBSDKTransactions(
            from: allBSDKTransactions,
            cache: &bsdkTransactionsGroupedByDestinationAddressString
        )

        guard let bsdkTransactionsCandidatesByReceiver = bsdkTransactionsGroupedByDestinationAddressString[
            lowerCasedAddressStringIfNeeded(rule.address)
        ] else {
            return nil
        }

        return bsdkTransactionsCandidatesByReceiver
            .filter { bsdkTransaction in
                guard
                    bsdkTransaction.isOutgoing,
                    !consumedBSDKTransactionsIds.contains(bsdkTransaction.id),
                    // The sender of the pay-in leg must be the owner
                    isSentByOwner(bsdkTransaction)
                else {
                    return false
                }

                // Compare against the amount sent to the pay-in (deposit) address specifically (filtering UTXO change output, etc)
                let amountToPayIn = bsdkTransaction.destinationAmount(
                    to: rule.address,
                    addressConverter: lowerCasedAddressStringIfNeeded
                )
                return rule.matches(amount: amountToPayIn)
            }
            .min(by: \.normalizedDate) // Select the earliest transaction
    }

    func heuristicallyMatchingReceiveBSDKTransaction(
        for exchangeTransaction: ExchangeTransaction,
        // Optional and inout argument, so it will be lazily created on demand and cached for future calls to avoid O(n) * O(m) complexity
        bsdkTransactionsGroupedByDestinationAddressString: inout [String: [TransactionRecord]]?,
        allBSDKTransactions: [TransactionRecord],
        consumedBSDKTransactionsIds: Set<TransactionRecord.ID>
    ) -> TransactionRecord? {
        guard
            exchangeTransaction.status != .refunded,
            exchangeTransaction.to.currency == normalizedCurrentCurrency
        else {
            return nil
        }

        let rule = legRule(for: .payOut, of: exchangeTransaction)

        // Prevents division by zero
        guard rule.targetAmount > 0 else {
            return nil
        }

        let bsdkTransactionsGroupedByDestinationAddressString = makeDestinationAddressGroupedBSDKTransactions(
            from: allBSDKTransactions,
            cache: &bsdkTransactionsGroupedByDestinationAddressString
        )

        let targetDateRange = exchangeTransaction.createdAt ... exchangeTransaction.createdAt.advanced(by: Constants.receiveHeuristicTimeWindow)
        let addressIndexedCandidates = bsdkTransactionsGroupedByDestinationAddressString[
            lowerCasedAddressStringIfNeeded(rule.address)
        ]

        if let addressIndexedCandidates, let match = earliestPayOutLegMatch(
            among: addressIndexedCandidates,
            rule: rule,
            targetDateRange: targetDateRange,
            consumedBSDKTransactionsIds: consumedBSDKTransactionsIds
        ) {
            return match
        }

        // Not every provider reports the counterparty as the destination of a token transfer, which keeps the
        // pay-out leg out of the address index — while the index may still hold other records that did land on
        // the pay-out address. All the records are therefore considered when the indexed ones yield nothing,
        // which is safe for this leg specifically: it arrives at the user's own address, so the address carries
        // little information here, while the direction, amount, time window and sender checks still hold. The
        // pay-in leg has no such fallback — there the address is the provider's deposit address and is the only
        // thing telling a deposit from an ordinary transfer of the same amount.
        return earliestPayOutLegMatch(
            among: allBSDKTransactions,
            rule: rule,
            targetDateRange: targetDateRange,
            consumedBSDKTransactionsIds: consumedBSDKTransactionsIds
        )
    }

    private func earliestPayOutLegMatch(
        among candidates: [TransactionRecord],
        rule: ExpressLegRule,
        targetDateRange: ClosedRange<Date>,
        consumedBSDKTransactionsIds: Set<TransactionRecord.ID>
    ) -> TransactionRecord? {
        return candidates
            .filter { bsdkTransaction in
                guard
                    !bsdkTransaction.isOutgoing,
                    !consumedBSDKTransactionsIds.contains(bsdkTransaction.id),
                    targetDateRange.contains(bsdkTransaction.normalizedDate),
                    !isSentByOwner(bsdkTransaction)
                else {
                    return false
                }

                return rule.matches(amount: legAmount(of: bsdkTransaction, rule: rule))
            }
            .min(by: \.normalizedDate)
    }

    func heuristicallyMatchingRefundBSDKTransaction(
        for exchangeTransaction: ExchangeTransaction,
        from bsdkTransactions: [TransactionRecord],
        consumedBSDKTransactionsIds: Set<TransactionRecord.ID>
    ) -> TransactionRecord? {
        guard
            exchangeTransaction.status == .refunded,
            exchangeTransaction.refund?.currency == normalizedCurrentCurrency
        else {
            return nil
        }

        let targetAmount = exchangeTransaction.from.normalizedAmount

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
        consumedBSDKTransactionsIds: Set<TransactionRecord.ID>
    ) -> TransactionRecord? {
        guard
            onrampTransaction.to.currency == normalizedCurrentCurrency,
            let targetAmount = onrampTransaction.to.normalizedAmount
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

    private func isSentByOwner(_ bsdkTransaction: TransactionRecord) -> Bool {
        return bsdkTransaction.source.sources.contains { source in
            walletModelAddresses.contains(lowerCasedAddressStringIfNeeded(source.address))
        }
    }

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

            if lhs.hash != rhs.hash {
                return lhs.hash < rhs.hash // hash ASC
            }

            return lhs.index < rhs.index // index ASC
        }
    }

    @inline(__always)
    private func shouldAddSyntheticTransaction(from exchangeTransaction: ExchangeTransaction) -> Bool {
        switch exchangeTransaction.status {
        case .created:
            return exchangeTransaction.payIn.hash != nil
        case .unknown,
             .preview,
             .exchangeTxSent,
             .waiting,
             .waitingTxHash,
             .expired,
             .confirming,
             .exchanging,
             .sending,
             .finished,
             .failed,
             .txFailed,
             .refunded,
             .verifying,
             .paused:
            return true
        }
    }

    @inline(__always)
    private func shouldAddSyntheticTransaction(from onrampTransaction: OnrampTransaction) -> Bool {
        return true // Currently, there are no restrictions on onramp synthetic transactions creation
    }

    @inline(__always)
    private func lowerCasedAddressStringIfNeeded(_ address: String) -> String {
        return TransactionHistoryAddressNormalizer.normalize(address, isEvm: isEvm)
    }
}

// MARK: - Auxiliary types

private extension TransactionHistoryExpressDataMerger {
    /// The on-chain leg of an exchange transaction: the deposit sent to the provider or the pay-out received from it.
    enum ExpressLeg {
        case payIn
        case payOut
    }

    /// What makes an on-chain record the given leg of a deal: the direction, the address the amount has to land
    /// on, the amount itself and how far off it is allowed to be. Shared by the hash-based claiming and by the
    /// heuristic matchers so both agree on what a leg looks like.
    struct ExpressLegRule {
        let isOutgoing: Bool
        let address: String
        let targetAmount: Decimal
        let amountTolerance: Decimal

        func matches(amount: Decimal) -> Bool {
            abs(amount - targetAmount) <= amountTolerance * targetAmount
        }
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

private extension Array {
    func partitioned(by isMatching: (Element) -> Bool) -> (matching: [Element], rest: [Element]) {
        var matching: [Element] = []
        var rest: [Element] = []

        for element in self {
            isMatching(element) ? matching.append(element) : rest.append(element)
        }

        return (matching, rest)
    }
}

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

    var destinationAddresses: [String] {
        destination.destinations.map(\.address.string)
    }
}
