//
//  KeychainCollectiblesSessionKeyWalletIdStoreTests.swift
//  TangemCollectiblesTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
@testable import TangemCollectibles

@Suite("KeychainCollectiblesSessionKeyWalletIdStore")
struct KeychainCollectiblesSessionKeyWalletIdStoreTests {
    typealias SUT = KeychainCollectiblesSessionKeyWalletIdStore

    @Test("Writes the raw id under the prefixed, lowercased account of the wallet")
    func writesUnderPrefixedLowercasedAccount() throws {
        let (sut, storage) = makeSUT()

        try sut.setSessionKeyWalletId(Constants.sessionKeyWalletId, for: Constants.userWalletId)

        #expect(storage.entries == [Constants.account: Constants.sessionKeyWalletId.value])
    }

    @Test("Reads the entry under the wallet's account back as the session key wallet id")
    func readsEntryUnderAccount() throws {
        let (sut, _) = makeSUT(entries: [Constants.account: Constants.sessionKeyWalletId.value])

        #expect(try sut.sessionKeyWalletId(for: Constants.userWalletId) == Constants.sessionKeyWalletId)
    }

    @Test("No entry means no session key wallet")
    func missingEntryReadsAsNil() throws {
        let (sut, _) = makeSUT()

        #expect(try sut.sessionKeyWalletId(for: Constants.userWalletId) == nil)
    }

    @Test("Overwrites the entry of a wallet that already holds one")
    func overwritesHeldEntry() throws {
        let (sut, storage) = makeSUT(entries: [Constants.account: Constants.sessionKeyWalletId.value])

        try sut.setSessionKeyWalletId(Constants.otherSessionKeyWalletId, for: Constants.userWalletId)

        #expect(storage.entries == [Constants.account: Constants.otherSessionKeyWalletId.value])
    }

    @Test("Clearing the mapping deletes the entry")
    func clearingDeletesEntry() throws {
        let (sut, storage) = makeSUT(entries: [Constants.account: Constants.sessionKeyWalletId.value])

        try sut.setSessionKeyWalletId(nil, for: Constants.userWalletId)

        #expect(storage.entries.isEmpty)
    }

    @Test("Wallets keep separate entries")
    func walletsKeepSeparateEntries() throws {
        let (sut, _) = makeSUT()
        try sut.setSessionKeyWalletId(Constants.sessionKeyWalletId, for: Constants.userWalletId)
        try sut.setSessionKeyWalletId(Constants.otherSessionKeyWalletId, for: Constants.otherUserWalletId)

        try sut.setSessionKeyWalletId(nil, for: Constants.otherUserWalletId)

        #expect(try sut.sessionKeyWalletId(for: Constants.userWalletId) == Constants.sessionKeyWalletId)
        #expect(try sut.sessionKeyWalletId(for: Constants.otherUserWalletId) == nil)
    }

    @Test("Storage failures are not swallowed", arguments: StoreOperation.allCases)
    func storageFailurePropagates(operation: StoreOperation) {
        let (sut, storage) = makeSUT()
        storage.error = TestError.keychain

        #expect(throws: TestError.keychain) {
            try perform(operation, on: sut)
        }
    }
}

// MARK: - Arguments

extension KeychainCollectiblesSessionKeyWalletIdStoreTests {
    enum StoreOperation: CaseIterable {
        case read
        case write
        case clear
    }
}

// MARK: - Helpers

private extension KeychainCollectiblesSessionKeyWalletIdStoreTests {
    enum Constants {
        static let userWalletId = UserWalletId(value: Data([0xAB, 0xCD, 0xEF, 0x01]))
        static let otherUserWalletId = UserWalletId(value: Data([0x02, 0x03, 0x04, 0x05]))
        static let sessionKeyWalletId = UserWalletId(value: Data(repeating: 0x11, count: 32))
        static let otherSessionKeyWalletId = UserWalletId(value: Data(repeating: 0x22, count: 32))
        static let account = "collectibles_session_key_wallet_id_abcdef01"
    }

    func makeSUT(entries: [String: Data] = [:]) -> (SUT, SecureStorageFake) {
        let storage = SecureStorageFake(entries: entries)
        return (SUT(secureStorage: storage), storage)
    }

    func perform(_ operation: StoreOperation, on sut: SUT) throws {
        switch operation {
        case .read:
            _ = try sut.sessionKeyWalletId(for: Constants.userWalletId)
        case .write:
            try sut.setSessionKeyWalletId(Constants.sessionKeyWalletId, for: Constants.userWalletId)
        case .clear:
            try sut.setSessionKeyWalletId(nil, for: Constants.userWalletId)
        }
    }
}

// MARK: - Doubles

private enum TestError: Error {
    case keychain
    case duplicateEntry
}

private final class SecureStorageFake: CollectiblesSecureStorage {
    var error: (any Error)?
    private(set) var entries: [String: Data]

    init(entries: [String: Data]) {
        self.entries = entries
    }

    func get(_ account: String) throws -> Data? {
        try failIfRequested()
        return entries[account]
    }

    func store(_ object: Data, forKey account: String, overwrite: Bool) throws {
        try failIfRequested()

        guard overwrite || entries[account] == nil else {
            throw TestError.duplicateEntry
        }

        entries[account] = object
    }

    func delete(_ account: String) throws {
        try failIfRequested()
        entries[account] = nil
    }

    private func failIfRequested() throws {
        if let error {
            throw error
        }
    }
}
