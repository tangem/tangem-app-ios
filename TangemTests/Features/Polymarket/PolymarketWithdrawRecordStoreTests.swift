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

@Suite("Polymarket withdraw record store", .timeLimit(.minutes(1)))
struct PolymarketWithdrawRecordStoreTests {
    private let userWalletId = UserWalletId(value: Data([0x01, 0x02, 0x03]))
    private let otherUserWalletId = UserWalletId(value: Data([0x04, 0x05, 0x06]))
    private let deadline = Date(timeIntervalSince1970: 1_700_000_600)

    @Test("A withdrawal survives being read by a fresh store over the same storage")
    func survivesAFreshStore() {
        let storage = InMemoryPersistentStorage()
        let entry = makeEntry(state: .confirmed, transactionHash: "0x7ae1")

        makeStore(storage: storage).save(entry)

        #expect(makeStore(storage: storage).entry() == entry)
    }

    @Test("Deleting the withdrawal removes it from the storage")
    func deletesTheWithdrawal() {
        let storage = InMemoryPersistentStorage()
        makeStore(storage: storage).save(makeEntry(state: .inProgress))

        makeStore(storage: storage).delete()

        #expect(makeStore(storage: storage).entry() == nil)
        #expect(storage.paths.isEmpty)
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
        #expect(storage.paths.allSatisfy { $0.hasPrefix("polymarket_withdraw_record_") && !$0.caseInsensitiveContains(userWalletId.stringValue) })
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
}

// MARK: - Helpers

private extension PolymarketWithdrawRecordStoreTests {
    func makeStore(storage: PersistentStorageProtocol) -> PolymarketWithdrawRecordStore {
        PolymarketWithdrawRecordStore(userWalletId: userWalletId, storage: storage)
    }

    func makeEntry(state: PolymarketWithdrawState, transactionHash: String? = nil) -> PolymarketWithdrawRecordStore.Entry {
        PolymarketWithdrawRecordStore.Entry(
            record: PolymarketWithdrawRecord(transactionId: "tx-1", state: state, transactionHash: transactionHash),
            deadline: deadline,
            settledAt: state.isTerminal ? deadline.addingTimeInterval(-60) : nil
        )
    }
}
