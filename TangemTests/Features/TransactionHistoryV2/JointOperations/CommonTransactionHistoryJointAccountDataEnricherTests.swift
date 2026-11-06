//
//  CommonTransactionHistoryJointAccountDataEnricherTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Testing
@testable import Tangem

@Suite("CommonTransactionHistoryJointAccountDataEnricher")
struct CommonTransactionHistoryJointAccountDataEnricherTests {
    @Test("An operation of an active account is saved locally with the account's Safe, creation date and threshold")
    func operationOfActiveAccountIsSaved() async {
        let writer = JointOperationsHistoryWriterStub(isFailing: false)
        let sut = Self.makeSUT(status: .active(safeAddress: Self.checksummedSafeAddress), writer: writer)
        let operation = Self.operation()

        await sut.enrich(with: [operation], cryptoAccountId: Self.accountId)

        #expect(writer.savedLocalItems == [[
            JointOperationHistoryItem(
                operation: operation,
                cryptoAccountId: Self.accountId,
                safeAddress: Self.checksummedSafeAddress.lowercased(),
                createdAt: Self.createdAt,
                threshold: 2
            ),
        ]])
        #expect(writer.savedRemoteOperationIds.isEmpty)
    }

    @Test("The account is found whatever the case of its identifier")
    func accountIsFoundCaseInsensitively() async {
        let writer = JointOperationsHistoryWriterStub(isFailing: false)
        let sut = Self.makeSUT(status: .active(safeAddress: Self.checksummedSafeAddress), writer: writer)

        await sut.enrich(with: [Self.operation()], cryptoAccountId: Self.accountId.lowercased())

        #expect(writer.savedLocalItems.flatMap { $0 }.map(\.operation.id) == ["coin"])
    }

    @Test("An operation without its creation date or threshold is left for the history sync", arguments: MissingField.allCases)
    func operationWithoutCreationDateOrThresholdIsSkipped(missingField: MissingField) async {
        let writer = JointOperationsHistoryWriterStub(isFailing: false)
        let sut = Self.makeSUT(status: .active(safeAddress: Self.checksummedSafeAddress), writer: writer)
        let incomplete = JointAccountCompositionFixture.coinTransfer(
            id: "incomplete",
            createdAt: missingField == .createdAt ? nil : Self.createdAt,
            threshold: missingField == .threshold ? nil : 2
        )

        await sut.enrich(with: [incomplete, Self.operation(id: "complete")], cryptoAccountId: Self.accountId)

        #expect(writer.savedLocalItems.flatMap { $0 }.map(\.operation.id) == ["complete"])
    }

    @Test(
        "Nothing is saved for an account without an active Safe",
        arguments: [JointAccountStatus.pending, .confirming(safeAddress: Self.checksummedSafeAddress), .untrusted, .cancelled, .unknown]
    )
    func accountWithoutActiveSafeSavesNothing(status: JointAccountStatus) async {
        let writer = JointOperationsHistoryWriterStub(isFailing: false)
        let sut = Self.makeSUT(status: status, writer: writer)

        await sut.enrich(with: [Self.operation()], cryptoAccountId: Self.accountId)

        #expect(writer.savedLocalItems.isEmpty)
    }

    @Test("Nothing is saved for an account missing from the snapshot")
    func unknownAccountSavesNothing() async {
        let writer = JointOperationsHistoryWriterStub(isFailing: false)
        let sut = Self.makeSUT(status: .active(safeAddress: Self.checksummedSafeAddress), writer: writer)

        await sut.enrich(with: [Self.operation()], cryptoAccountId: "another-account")

        #expect(writer.savedLocalItems.isEmpty)
    }

    @Test("Removing passes the identifiers to the writer")
    func removalReachesTheWriter() async {
        let writer = JointOperationsHistoryWriterStub(isFailing: false)
        let sut = Self.makeSUT(status: .active(safeAddress: Self.checksummedSafeAddress), writer: writer)

        await sut.removeOperations(withIds: ["coin"])

        #expect(writer.deletedOperationIds == [["coin"]])
    }

    @Test("The factory gives an enricher only while joint accounts are on", arguments: [true, false])
    func factoryFollowsTheFeature(isJointAccountsAvailable: Bool) async {
        let factory = TransactionHistoryJointAccountDataEnricherFactory.make(
            persistentStorage: JointAccountsPersistentStorageReadingStub(accounts: []),
            isJointAccountsAvailable: isJointAccountsAvailable
        )

        #expect((await factory() != nil) == isJointAccountsAvailable)
    }
}

// MARK: - Helpers

extension CommonTransactionHistoryJointAccountDataEnricherTests {
    enum MissingField: CaseIterable {
        case createdAt
        case threshold
    }
}

private extension CommonTransactionHistoryJointAccountDataEnricherTests {
    static let accountId = JointAccountCompositionFixture.caseFlippedCryptoAccountId
    static let checksummedSafeAddress = "0x8F3Ac21B7e5F4552091a69125d5dFcB7B8C26590"
    static let createdAt = Date(timeIntervalSince1970: 1_767_225_600)

    static func operation(id: String = "coin") -> JointAccountOperation {
        JointAccountCompositionFixture.coinTransfer(id: id, createdAt: createdAt, threshold: 2)
    }

    static func makeSUT(status: JointAccountStatus, writer: JointOperationsHistoryWriter) -> CommonTransactionHistoryJointAccountDataEnricher {
        let account = JointAccountCompositionFixture.storedAccount(status: status, membersCount: 2, members: [])

        return CommonTransactionHistoryJointAccountDataEnricher(jointAccounts: [account], writer: writer)
    }
}

// MARK: - Stubs

private struct JointAccountsPersistentStorageReadingStub: JointAccountsPersistentStorage {
    let accounts: [StoredJointAccount]

    var didUpdatePublisher: AnyPublisher<Void, Never> {
        Empty().eraseToAnyPublisher()
    }

    func getList() -> [StoredJointAccount] {
        accounts
    }

    func appendNewOrUpdateExisting(_ account: StoredJointAccount) throws {}

    func updateInvite(_ invite: StoredJointAccount.Invite, ofAccountWith cryptoAccountId: String) throws {}

    func replace(with accounts: [StoredJointAccount]) throws {}
}
