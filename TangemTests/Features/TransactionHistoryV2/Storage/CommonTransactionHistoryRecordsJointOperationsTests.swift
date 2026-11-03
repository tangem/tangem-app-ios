//
//  CommonTransactionHistoryRecordsJointOperationsTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Testing
@testable import Tangem
@testable import BlockchainSdk

@Suite("Transaction history records: joint operations", .timeLimit(.minutes(1)))
struct CommonTransactionHistoryRecordsJointOperationsTests {
    @Test("A saved coin operation reaches the reader of the Safe's coin")
    func savedCoinOperationReachesCoinReader() async throws {
        let item = JointOperationHistoryTestDataFactory.coinItem(id: "joint")

        let records = try await withInjectedInMemoryAppDatabase {
            try await CommonTransactionHistoryRecordsWriter().save([item])
            return await firstNonEmptyRecords(for: Self.baseCoin)
        }

        #expect(records == [.jointOperation(JointOperationHistoryInfo(item: item))])
    }

    @Test("A saved token operation reaches the reader of the token, whatever the case of its contract")
    func savedTokenOperationReachesTokenReader() async throws {
        let item = try JointOperationHistoryTestDataFactory.tokenItem(id: "joint")

        let records = try await withInjectedInMemoryAppDatabase {
            try await CommonTransactionHistoryRecordsWriter().save([item])
            return await firstNonEmptyRecords(for: Self.baseUSDC)
        }

        #expect(records == [.jointOperation(JointOperationHistoryInfo(item: item))])
    }

    @Test("The latest state the history sent is kept, whatever the stored one", arguments: [
        (earlierStatus: JointAccountOperationStatus.awaitingSignatures, laterStatus: JointAccountOperationStatus.cancelled),
        (earlierStatus: .pending, laterStatus: .executed),
        (earlierStatus: .executed, laterStatus: .failed),
        (earlierStatus: .executed, laterStatus: .pending),
    ])
    func latestSavedStateIsKept(
        earlierStatus: JointAccountOperationStatus,
        laterStatus: JointAccountOperationStatus
    ) async throws {
        let earlier = JointOperationHistoryTestDataFactory.coinItem(id: "joint", status: earlierStatus)
        let later = JointOperationHistoryTestDataFactory.coinItem(id: "joint", status: laterStatus)

        let records = try await withInjectedInMemoryAppDatabase {
            let writer = CommonTransactionHistoryRecordsWriter()
            try await writer.save([earlier])
            try await writer.save([later])
            return await firstNonEmptyRecords(for: Self.baseCoin)
        }

        #expect(records == [.jointOperation(JointOperationHistoryInfo(item: later))])
    }

    @Test("Within one page the later state of an operation wins")
    func laterStateWithinOnePageWins() async throws {
        let finished = JointOperationHistoryTestDataFactory.coinItem(id: "joint", status: .failed)
        let inFlight = JointOperationHistoryTestDataFactory.coinItem(id: "joint", status: .pending)

        let records = try await withInjectedInMemoryAppDatabase {
            try await CommonTransactionHistoryRecordsWriter().save([finished, inFlight])
            return await firstNonEmptyRecords(for: Self.baseCoin)
        }

        #expect(records == [.jointOperation(JointOperationHistoryInfo(item: inFlight))])
    }

    @Test("Saving the same operation again leaves a single row")
    func savingSameOperationAgainIsIdempotent() async throws {
        let item = JointOperationHistoryTestDataFactory.coinItem(id: "joint")

        let records = try await withInjectedInMemoryAppDatabase {
            let writer = CommonTransactionHistoryRecordsWriter()
            try await writer.save([item])
            try await writer.save([item])
            return await firstNonEmptyRecords(for: Self.baseCoin)
        }

        #expect(records == [.jointOperation(JointOperationHistoryInfo(item: item))])
    }

    @Test("An operation of another token stays out of the coin's history")
    func tokenOperationStaysOutOfCoinHistory() async throws {
        let coinItem = JointOperationHistoryTestDataFactory.coinItem(id: "coin")
        let tokenItem = try JointOperationHistoryTestDataFactory.tokenItem(id: "token")

        let records = try await withInjectedInMemoryAppDatabase {
            try await CommonTransactionHistoryRecordsWriter().save([tokenItem, coinItem])
            return await firstNonEmptyRecords(for: Self.baseCoin)
        }

        #expect(records.map(\.groupingId) == ["coin"])
    }
}

// MARK: - Helpers

private extension CommonTransactionHistoryRecordsJointOperationsTests {
    static let baseCoin: TokenItem = .blockchain(.init(.base(testnet: false), derivationPath: nil))

    static let baseUSDC: TokenItem = .token(
        Token(
            name: "USD Coin",
            symbol: "USDC",
            contractAddress: JointOperationHistoryTestDataFactory.checksummedTokenContract,
            decimalCount: 6,
            id: "usd-coin"
        ),
        .init(.base(testnet: false), derivationPath: nil)
    )

    func firstNonEmptyRecords(for tokenItem: TokenItem) async -> [TransactionHistoryRecordsReader.Record] {
        let reader = CommonTransactionHistoryRecordsReader()
        defer { withExtendedLifetime(reader) {} }

        let updates = reader.updates(
            for: WalletModelId(tokenItem: tokenItem),
            walletModelAddressesPublisher: CurrentValueSubject<[String], Never>([JointOperationHistoryTestDataFactory.safeAddress])
        )

        for await records in updates where records.isNotEmpty {
            return records
        }

        return []
    }
}
