//
//  PolymarketWithdrawRecordStoreTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
import TangemPolymarket
@testable import Tangem

@Suite("Polymarket withdraw record store")
struct PolymarketWithdrawRecordStoreTests {
    private let userWalletId = UserWalletId(value: Data([0x01, 0x02, 0x03]))
    private let otherUserWalletId = UserWalletId(value: Data([0x04, 0x05, 0x06]))
    private let deadline = Date(timeIntervalSince1970: 1_700_000_600)

    @Test("A saved withdrawal is read back with the deadline of the batch that carries it")
    func readsBackTheSavedWithdrawal() {
        let store = makeStore(storage: InMemoryPersistentStorage())
        let entry = makeEntry(state: .inProgress, transactionHash: "0x7ae1")

        store.save(entry)

        #expect(store.entry() == entry)
    }

    @Test("A withdrawal survives being read by a fresh store over the same storage")
    func survivesAFreshStore() {
        let storage = InMemoryPersistentStorage()
        let entry = makeEntry(state: .confirmed)

        makeStore(storage: storage).save(entry)

        #expect(makeStore(storage: storage).entry() == entry)
    }

    @Test("A later save replaces the earlier one")
    func replacesTheEarlierSave() {
        let store = makeStore(storage: InMemoryPersistentStorage())
        store.save(makeEntry(state: .inProgress))

        store.save(makeEntry(state: .confirmed))

        #expect(store.entry()?.record.state == .confirmed)
    }

    @Test("A deleted withdrawal is gone")
    func deletesTheWithdrawal() {
        let store = makeStore(storage: InMemoryPersistentStorage())
        store.save(makeEntry(state: .inProgress))

        store.delete()

        #expect(store.entry() == nil)
    }

    @Test("Wallets do not see each other's withdrawals")
    func keepsWalletsApart() {
        let storage = InMemoryPersistentStorage()
        makeStore(storage: storage).save(makeEntry(state: .inProgress))

        let other = PolymarketWithdrawRecordStore(userWalletId: otherUserWalletId, storage: storage)

        #expect(other.entry() == nil)
    }

    @Test("The file name never carries the wallet id itself")
    func keepsTheWalletIdOutOfTheFileName() {
        let storage = InMemoryPersistentStorage()

        makeStore(storage: storage).save(makeEntry(state: .inProgress))

        #expect(storage.paths.count == 1)
        #expect(storage.paths.allSatisfy { $0.hasPrefix("polymarket_withdraw_record_") && !$0.contains(userWalletId.stringValue) })
    }

    @Test("A state this build does not know is read back as unknown, not as a failure to read")
    func readsAnUnknownStateAsUnknown() throws {
        let storage = InMemoryPersistentStorage()
        let store = makeStore(storage: storage)
        store.save(makeEntry(state: .inProgress))
        let path = try #require(storage.paths.first)

        storage.overwrite(path: path, json: #"{"record":{"transactionId":"tx-1","state":"SETTLING"},"deadline":0,"settledAt":null}"#)

        #expect(store.entry()?.record.state == .unknown)
    }

    @Test("A storage that refuses to write leaves nothing behind and does not crash the flow")
    func toleratesAStorageThatRefusesToWrite() {
        let storage = InMemoryPersistentStorage()
        storage.storeError = StubError()
        let store = makeStore(storage: storage)

        store.save(makeEntry(state: .inProgress))

        #expect(store.entry() == nil)
    }
}

// MARK: - Helpers

private extension PolymarketWithdrawRecordStoreTests {
    func makeStore(storage: PersistentStorageProtocol) -> PolymarketWithdrawRecordStore {
        PolymarketWithdrawRecordStore(userWalletId: userWalletId, storage: storage)
    }

    func makeEntry(
        transactionId: String = "tx-1",
        state: PolymarketWithdrawState,
        transactionHash: String? = nil
    ) -> PolymarketWithdrawRecordStore.Entry {
        PolymarketWithdrawRecordStore.Entry(
            record: PolymarketWithdrawRecord(transactionId: transactionId, state: state, transactionHash: transactionHash),
            deadline: deadline,
            settledAt: state.isTerminal ? deadline.addingTimeInterval(-60) : nil
        )
    }

    struct StubError: Error {}
}
