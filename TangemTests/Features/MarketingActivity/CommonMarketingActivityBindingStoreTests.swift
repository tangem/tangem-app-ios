//
//  CommonMarketingActivityBindingStoreTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("CommonMarketingActivityBindingStore")
struct CommonMarketingActivityBindingStoreTests {
    private let storage = InMemoryPersistentStorage()

    @Test("A uid is written to disk the moment it is added")
    func addPersists() async throws {
        let store = makeStore()

        let binding = await store.add(uid: "uid-1")

        #expect(binding.uid == "uid-1")
        #expect(await store.pending() == [binding])
        #expect(try storedBindings() == [binding])
    }

    @Test("Different uids are kept as separate requests")
    func differentUids() async {
        let store = makeStore()

        await store.add(uid: "uid-1")
        await store.add(uid: "uid-2")

        #expect(await store.pending().map(\.uid) == ["uid-1", "uid-2"])
    }

    @Test("The same uid waiting twice is one request")
    func sameUidIsOneRequest() async throws {
        let store = makeStore()

        let first = await store.add(uid: "uid-1")
        let second = await store.add(uid: "uid-1")

        #expect(first == second)
        #expect(await store.pending() == [first])
        #expect(try storedBindings() == [first])
    }

    @Test("The uid is matched exactly, case included")
    func uidIsMatchedExactly() async {
        let store = makeStore()

        await store.add(uid: "uid-1")
        await store.add(uid: "UID-1")

        #expect(await store.pending().map(\.uid) == ["uid-1", "UID-1"])
    }

    @Test("A removed request is gone from the store and the disk")
    func remove() async throws {
        let store = makeStore()

        let sent = await store.add(uid: "uid-1")
        let waiting = await store.add(uid: "uid-2")
        await store.remove(id: sent.id)

        #expect(await store.pending() == [waiting])
        #expect(try storedBindings() == [waiting])
    }

    @Test("A uid opened again after its request was sent is a new request")
    func reopenedAfterRemoval() async {
        let store = makeStore()

        let sent = await store.add(uid: "uid-1")
        await store.remove(id: sent.id)
        let reopened = await store.add(uid: "uid-1")

        #expect(reopened.id != sent.id)
        #expect(await store.pending() == [reopened])
    }

    @Test("Requests survive a restart")
    func survivesRestart() async {
        let firstLaunch = makeStore()
        await firstLaunch.add(uid: "uid-1")
        await firstLaunch.add(uid: "uid-2")

        let secondLaunch = makeStore()

        #expect(await secondLaunch.pending() == firstLaunch.pending())
        #expect(await secondLaunch.pending().map(\.uid) == ["uid-1", "uid-2"])
    }

    @Test("A file that can't be read is replaced, so new requests are saved again")
    func unreadableFileIsReplaced() async throws {
        try storage.store(value: "not a list of bindings", for: .marketingActivityBindings)
        let store = makeStore()

        let added = await store.add(uid: "uid-1")

        #expect(await store.pending() == [added])
        #expect(try storedBindings() == [added])
    }

    @Test("A request that failed to be written is written on the next access")
    func failedAdditionIsWrittenLater() async throws {
        let store = makeStore()
        storage.storeError = CocoaError(.fileWriteOutOfSpace)

        let added = await store.add(uid: "uid-1")
        #expect(try storedBindings().isEmpty)

        storage.storeError = nil
        _ = await store.pending()

        #expect(try storedBindings() == [added])
    }

    @Test("A removal that failed to be written is written when it's repeated")
    func failedRemovalIsWrittenLater() async throws {
        let store = makeStore()
        let sent = await store.add(uid: "uid-1")
        storage.storeError = CocoaError(.fileWriteOutOfSpace)

        await store.remove(id: sent.id)
        #expect(try storedBindings() == [sent])

        storage.storeError = nil
        await store.remove(id: sent.id)

        #expect(try storedBindings().isEmpty)
    }
}

// MARK: - Helpers

private extension CommonMarketingActivityBindingStoreTests {
    func makeStore() -> CommonMarketingActivityBindingStore {
        CommonMarketingActivityBindingStore(persistentStorage: storage)
    }

    func storedBindings() throws -> [MarketingActivityBinding] {
        try storage.value(for: .marketingActivityBindings) ?? []
    }
}
