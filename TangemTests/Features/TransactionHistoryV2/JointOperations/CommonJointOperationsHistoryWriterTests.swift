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
    @Test("Saving from the API writes every known stage and leaves out the unknown one")
    func remoteSaveSkipsUnknown() async throws {
        let writer = TransactionHistoryRecordsWriterStub(isFailing: false)
        let sut = CommonJointOperationsHistoryWriter(writer: writer)

        try await sut.save(remote: [
            JointOperationHistoryTestDataFactory.coinItem(id: "executed", status: .executed),
            JointOperationHistoryTestDataFactory.coinItem(id: "unknown", status: .unknown),
            JointOperationHistoryTestDataFactory.coinItem(id: "pending", status: .pending),
        ])

        #expect(writer.savedOperationIds == [["executed", "pending"]])
        #expect(writer.writtenResolvers.isEmpty)
    }

    @Test("Saving locally hands every item to a single write, so the stored stages are checked inside it")
    func localSaveGoesThroughOneWrite() async throws {
        let writer = TransactionHistoryRecordsWriterStub(isFailing: false)
        let sut = CommonJointOperationsHistoryWriter(writer: writer)

        try await sut.save(local: [
            JointOperationHistoryTestDataFactory.coinItem(id: "first", status: .pending),
            JointOperationHistoryTestDataFactory.coinItem(id: "second", status: .unknown),
        ])

        let resolvers = writer.writtenResolvers.compactMap { $0 as? JointOperationsLocalSaveResolver }
        #expect(resolvers.map { $0.items.map(\.operation.id) } == [["first", "second"]])
        #expect(writer.writtenResolvers.count == 1)
        #expect(writer.savedOperationIds.isEmpty)
    }

    @Test("Deleting hands the identifiers to a single write")
    func deleteGoesThroughOneWrite() async throws {
        let writer = TransactionHistoryRecordsWriterStub(isFailing: false)
        let sut = CommonJointOperationsHistoryWriter(writer: writer)

        try await sut.delete(operationIds: ["joint"])

        let resolvers = writer.writtenResolvers.compactMap { $0 as? JointOperationsDeleteResolver }
        #expect(resolvers.map(\.operationIds) == [["joint"]])
        #expect(writer.writtenResolvers.count == 1)
    }

    @Test("Nothing reaches the database when there is nothing to save or delete")
    func emptyInputWritesNothing() async throws {
        let writer = TransactionHistoryRecordsWriterStub(isFailing: false)
        let sut = CommonJointOperationsHistoryWriter(writer: writer)

        try await sut.save(local: [])
        try await sut.delete(operationIds: [])

        #expect(writer.writtenResolvers.isEmpty)
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

        #expect(records == [.jointOperation(JointOperationHistoryInfo(item: pending))])
    }

    @Test("A local in-flight write leaves a finished row in the database as it was", arguments: [JointAccountOperationStatus.executed, .cancelled])
    func localInFlightKeepsFinishedRowInDatabase(finishedStatus: JointAccountOperationStatus) async throws {
        let finished = JointOperationHistoryTestDataFactory.coinItem(id: "joint", status: finishedStatus)

        let records = try await withInjectedInMemoryAppDatabase {
            let sut = Self.makeDatabaseBackedSUT()
            try await sut.save(remote: [finished])
            try await sut.save(local: [JointOperationHistoryTestDataFactory.coinItem(id: "joint", status: .awaitingSignatures)])
            return await Self.firstNonEmptyRecords()
        }

        #expect(records == [.jointOperation(JointOperationHistoryInfo(item: finished))])
    }

    @Test("Saving locally writes exactly what the stored stages allow")
    func localSaveWritesWhatTheRuleAllows() async throws {
        let finished = JointOperationHistoryTestDataFactory.coinItem(id: "finished", status: .executed)
        let advanced = JointOperationHistoryTestDataFactory.coinItem(id: "in-flight", status: .pending)
        let new = JointOperationHistoryTestDataFactory.coinItem(id: "new", status: .awaitingSignatures)

        let records = try await withInjectedInMemoryAppDatabase {
            let sut = Self.makeDatabaseBackedSUT()
            try await sut.save(remote: [
                finished,
                JointOperationHistoryTestDataFactory.coinItem(id: "in-flight", status: .awaitingSignatures),
            ])
            try await sut.save(local: [
                JointOperationHistoryTestDataFactory.coinItem(id: "finished", status: .pending),
                advanced,
                new,
                JointOperationHistoryTestDataFactory.coinItem(id: "unknown", status: .unknown),
            ])
            return await Self.firstNonEmptyRecords()
        }

        #expect(Set(records) == Set([finished, advanced, new].map { .jointOperation(JointOperationHistoryInfo(item: $0)) }))
    }

    @Test("A deleted operation leaves the database, and the other one stays")
    func deleteRemovesTheRow() async throws {
        let kept = JointOperationHistoryTestDataFactory.coinItem(id: "kept")

        let records = try await withInjectedInMemoryAppDatabase {
            let sut = Self.makeDatabaseBackedSUT()
            try await sut.save(remote: [JointOperationHistoryTestDataFactory.coinItem(id: "deleted"), kept])
            try await sut.delete(operationIds: ["deleted"])
            return await Self.firstNonEmptyRecords()
        }

        #expect(records == [.jointOperation(JointOperationHistoryInfo(item: kept))])
    }

    @Test("A deleted operation takes its index rows along, so saving it again for another token keeps it out of the coin's history")
    func deleteRemovesTheIndexRows() async throws {
        let kept = JointOperationHistoryTestDataFactory.coinItem(id: "kept")

        let records = try await withInjectedInMemoryAppDatabase {
            let sut = Self.makeDatabaseBackedSUT()
            try await sut.save(remote: [JointOperationHistoryTestDataFactory.coinItem(id: "reused"), kept])
            try await sut.delete(operationIds: ["reused"])
            try await sut.save(remote: [JointOperationHistoryTestDataFactory.tokenItem(id: "reused")])
            return await Self.firstNonEmptyRecords()
        }

        #expect(records == [.jointOperation(JointOperationHistoryInfo(item: kept))])
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
