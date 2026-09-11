//
//  TransactionHistoryMapperDustFilterTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import BlockchainSdk
@testable import Tangem

/// Covers how the mapper feeds the dust filter: which amount it derives per record and what the filtered
/// result does to grouping. The threshold and the per-type decision live in `TransactionHistoryDustFilterTests`.
@Suite("TransactionHistoryMapper dust filtering")
struct TransactionHistoryMapperDustFilterTests {
    /// 100 USD per token, with amounts picked so that `amount * usdRate` is an exact number of cents.
    private let usdRate = Decimal(100)
    /// 0.009 USD
    private let belowThreshold = Decimal(9) / Decimal(100_000)
    /// 0.02 USD
    private let aboveThreshold = Decimal(2) / Decimal(10_000)

    // MARK: - Amount derivation

    @Test("Outgoing transfer below the threshold is hidden")
    func outgoingTransferBelowThresholdIsHidden() {
        let record = makeRecord(hash: "dust", amount: belowThreshold, isOutgoing: true, date: Self.baseDate)

        #expect(mapRecords([record]).isEmpty)
    }

    @Test("Incoming transfer below the threshold is hidden")
    func incomingTransferBelowThresholdIsHidden() {
        let record = makeRecord(hash: "dust", amount: belowThreshold, isOutgoing: false, date: Self.baseDate)

        #expect(mapRecords([record]).isEmpty)
    }

    @Test("Transfer above the threshold is shown")
    func transferAboveThresholdIsShown() {
        let record = makeRecord(hash: "visible", amount: aboveThreshold, isOutgoing: true, date: Self.baseDate)

        #expect(hashes(mapRecords([record])) == ["visible"])
    }

    @Test("Change is excluded from the outgoing amount before the threshold is applied")
    func outgoingAmountExcludesChange() {
        // Sends `aboveThreshold + belowThreshold` and gets `aboveThreshold` back as change, so the amount the row
        // shows — and the one the threshold is applied to — is `belowThreshold`.
        let record = TransactionRecord(
            hash: "dust",
            index: 0,
            source: .multiple([.init(address: Self.ownAddress, amount: aboveThreshold + belowThreshold)]),
            destination: .multiple([
                .init(address: .user(Self.counterpartyAddress), amount: belowThreshold),
                .init(address: .user(Self.ownAddress), amount: aboveThreshold),
            ]),
            fee: ExpressMergeTestDataFactory.ethereumToken.zeroFee,
            status: .confirmed,
            isOutgoing: true,
            type: .transfer,
            date: Self.baseDate,
            tokenTransfers: [],
            nonce: nil
        )

        #expect(mapRecords([record]).isEmpty)
    }

    @Test("Direction reaches the filter: outgoing staking survives the threshold, incoming staking doesn't")
    func stakingIsFilteredByDirection() {
        let outgoing = makeStakingRecord(hash: "outgoing", type: .stake, isOutgoing: true)
        let incoming = makeStakingRecord(hash: "incoming", type: .claimRewards, isOutgoing: false)

        #expect(hashes(mapRecords([outgoing, incoming])) == ["outgoing"])
    }

    // MARK: - Filtering is opt-in

    @Test("Mapper without a rate keeps everything")
    func mapperWithoutRateKeepsEverything() {
        let record = makeRecord(hash: "dust", amount: belowThreshold, isOutgoing: true, date: Self.baseDate)

        let items = makeSUT().mapTransactionListItem(
            from: [record],
            groupingStyle: .day(.short),
            dustFilter: TransactionHistoryDustFilter(usdRate: nil),
            subtitleOwnerResolver: nil
        )

        #expect(hashes(items) == ["dust"])
    }

    // MARK: - Grouping

    @Test("A day made entirely of dust leaves no empty section")
    func fullyFilteredDayProducesNoSection() {
        let previousDay = Self.baseDate.addingTimeInterval(-ExpressMergeTestDataFactory.dayInSeconds)

        let items = mapRecords([
            makeRecord(hash: "dust1", amount: belowThreshold, isOutgoing: true, date: previousDay),
            makeRecord(hash: "dust2", amount: belowThreshold, isOutgoing: true, date: previousDay),
            makeRecord(hash: "visible", amount: aboveThreshold, isOutgoing: true, date: Self.baseDate),
        ])

        #expect(items.count == 1)
        #expect(items[0].items.map(\.hash) == ["visible"])
    }
}

// MARK: - Helpers

private extension TransactionHistoryMapperDustFilterTests {
    static let ownAddress = "0xSource"
    static let counterpartyAddress = "0xCounterparty"
    static let baseDate = ExpressMergeTestDataFactory.baseDate

    func makeSUT() -> Tangem.TransactionHistoryMapper {
        Tangem.TransactionHistoryMapper(
            currencySymbol: "ETH",
            addressesProvider: StubTransactionHistoryAddressesProvider(walletAddresses: [Self.ownAddress]),
            showSign: true,
            isToken: false
        )
    }

    func mapRecords(_ records: [TransactionRecord]) -> [TransactionListItem] {
        makeSUT().mapTransactionListItem(
            from: records,
            groupingStyle: .day(.short),
            dustFilter: TransactionHistoryDustFilter(usdRate: usdRate),
            subtitleOwnerResolver: nil
        )
    }

    func hashes(_ items: [TransactionListItem]) -> [String] {
        items.flatMap(\.items).map(\.hash)
    }

    func makeStakingRecord(
        hash: String,
        type: TransactionRecord.TransactionType.StakingTransactionType,
        isOutgoing: Bool
    ) -> TransactionRecord {
        TransactionRecord(
            hash: hash,
            index: 0,
            source: .single(.init(address: isOutgoing ? Self.ownAddress : Self.counterpartyAddress, amount: belowThreshold)),
            destination: .single(
                .init(address: .user(isOutgoing ? Self.counterpartyAddress : Self.ownAddress), amount: belowThreshold)
            ),
            fee: ExpressMergeTestDataFactory.ethereumToken.zeroFee,
            status: .confirmed,
            isOutgoing: isOutgoing,
            type: .staking(type: type, target: nil),
            date: Self.baseDate,
            tokenTransfers: [],
            nonce: nil
        )
    }

    func makeRecord(hash: String, amount: Decimal, isOutgoing: Bool, date: Date) -> TransactionRecord {
        TransactionRecord(
            hash: hash,
            index: 0,
            source: .single(.init(address: isOutgoing ? Self.ownAddress : Self.counterpartyAddress, amount: amount)),
            destination: .single(
                .init(address: .user(isOutgoing ? Self.counterpartyAddress : Self.ownAddress), amount: amount)
            ),
            fee: ExpressMergeTestDataFactory.ethereumToken.zeroFee,
            status: .confirmed,
            isOutgoing: isOutgoing,
            type: .transfer,
            date: date,
            tokenTransfers: [],
            nonce: nil
        )
    }
}

// MARK: - Stubs

private struct StubTransactionHistoryAddressesProvider: WalletModelTransactionHistoryAddressesProvider {
    let walletAddresses: [String]
}
