//
//  StoredCollectiblesAccountPresenceStoreTests.swift
//  TangemCollectiblesTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
@testable import TangemCollectibles

@Suite("StoredCollectiblesAccountPresenceStore")
struct StoredCollectiblesAccountPresenceStoreTests {
    typealias SUT = StoredCollectiblesAccountPresenceStore

    @Test("A wallet nobody marked has no account")
    func unmarkedWalletHasNoAccount() {
        let (sut, storage) = makeSUT()

        #expect(!sut.contains(Constants.userWalletId))
        #expect(storage.writeCount == 0)
    }

    @Test("Marks the wallet under the salted hash of its id, never the id itself")
    func marksUnderSaltedHash() {
        let (sut, storage) = makeSUT()

        sut.insert(Constants.userWalletId)

        #expect(storage.collectiblesHasAccount == [Constants.saltedHash: true])
        #expect(sut.contains(Constants.userWalletId))
    }

    @Test("A store with another salt does not see the mark")
    func saltScopesTheMark() {
        let (sut, storage) = makeSUT()
        let otherSaltedStore = SUT(storage: storage, hashSalt: "other_salt")

        sut.insert(Constants.userWalletId)

        #expect(!otherSaltedStore.contains(Constants.userWalletId))
    }

    @Test("Marking an already marked wallet writes nothing")
    func repeatedMarkWritesNothing() {
        let (sut, storage) = makeSUT(marked: [Constants.userWalletId])

        sut.insert(Constants.userWalletId)

        #expect(storage.writeCount == 0)
    }

    @Test("Unmarking drops the record instead of flipping it to false")
    func unmarkDropsRecord() {
        let (sut, storage) = makeSUT(marked: [Constants.userWalletId])

        sut.remove(Constants.userWalletId)

        #expect(storage.collectiblesHasAccount.isEmpty)
        #expect(!sut.contains(Constants.userWalletId))
    }

    @Test("Unmarking a wallet that was never marked writes nothing")
    func unmarkingUnmarkedWritesNothing() {
        let (sut, storage) = makeSUT()

        sut.remove(Constants.userWalletId)

        #expect(storage.writeCount == 0)
    }

    @Test("Wallets are marked independently")
    func walletsAreMarkedIndependently() {
        let (sut, _) = makeSUT(marked: [Constants.userWalletId, Constants.otherUserWalletId])

        sut.remove(Constants.otherUserWalletId)

        #expect(sut.contains(Constants.userWalletId))
        #expect(!sut.contains(Constants.otherUserWalletId))
    }
}

// MARK: - Helpers

private extension StoredCollectiblesAccountPresenceStoreTests {
    enum Constants {
        static let salt = "test_salt"
        static let userWalletId = UserWalletId(value: Data(repeating: 0x11, count: 32))
        static let otherUserWalletId = UserWalletId(value: Data(repeating: 0x22, count: 32))
        static let saltedHash = "B7BB5B0E6D8DB3F370D174F30589F4F95979DA747FFD9D3D9EA0BFD3B0242CFB"
    }

    func makeSUT(marked: [UserWalletId] = []) -> (SUT, PresenceStorageFake) {
        let entries = Dictionary(uniqueKeysWithValues: marked.map { ($0.hashedStringValue(message: Constants.salt), true) })
        let storage = PresenceStorageFake(entries: entries)
        return (SUT(storage: storage, hashSalt: Constants.salt), storage)
    }
}

// MARK: - Doubles

private final class PresenceStorageFake: CollectiblesPresenceStorage {
    var collectiblesHasAccount: [String: Bool] {
        didSet { writeCount += 1 }
    }

    private(set) var writeCount = 0

    init(entries: [String: Bool]) {
        collectiblesHasAccount = entries
    }
}
