//
//  CommonJointOperationsHistoryWriterTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Testing
@testable import Tangem

@Suite("CommonJointOperationsHistoryWriter", .timeLimit(.minutes(1)))
struct CommonJointOperationsHistoryWriterTests {
    @Test("Saving from the API hands every item to the records writer in one save")
    func remoteSaveHandsItemsOver() async throws {
        let writer = TransactionHistoryRecordsWriterStub(isFailing: false)
        let sut = CommonJointOperationsHistoryWriter(writer: writer)

        try await sut.save(remote: [
            JointOperationHistoryTestDataFactory.coinItem(id: "executed", status: .executed),
            JointOperationHistoryTestDataFactory.coinItem(id: "unknown", status: .unknown),
            JointOperationHistoryTestDataFactory.coinItem(id: "pending", status: .pending),
        ])

        #expect(writer.savedOperationIds == [["executed", "unknown", "pending"]])
    }

    @Test("Saving from the API overwrites a finished operation with an in-flight one")
    func remoteSaveOverwritesFinished() async throws {
        let pending = JointOperationHistoryTestDataFactory.coinItem(id: "joint", status: .pending)

        let records = try await withInjectedInMemoryAppDatabase {
            let sut = Self.makeDatabaseBackedSUT()
            try await sut.save(remote: [JointOperationHistoryTestDataFactory.coinItem(id: "joint", status: .executed)])
            try await sut.save(remote: [pending])
            return await Self.firstNonEmptyRecords()
        }

        let expectedInfo = try JointOperationHistoryTestDataFactory.info(pending)
        #expect(records == [.jointOperation(expectedInfo)])
    }
}

// MARK: - Helpers

private extension CommonJointOperationsHistoryWriterTests {
    static func makeDatabaseBackedSUT() -> CommonJointOperationsHistoryWriter {
        CommonJointOperationsHistoryWriter(writer: CommonTransactionHistoryRecordsWriter())
    }

    static func firstNonEmptyRecords() async -> [TransactionHistoryRecordsReader.Record] {
        let reader = CommonTransactionHistoryRecordsReader()
        defer { withExtendedLifetime(reader) {} }

        let updates = reader.updates(
            for: WalletModelId(tokenItem: .blockchain(.init(.base(testnet: false), derivationPath: nil))),
            walletModelAddressesPublisher: CurrentValueSubject<[String], Never>([JointOperationHistoryTestDataFactory.safeAddress])
        )

        for await records in updates where records.isNotEmpty {
            return records
        }

        return []
    }
}
