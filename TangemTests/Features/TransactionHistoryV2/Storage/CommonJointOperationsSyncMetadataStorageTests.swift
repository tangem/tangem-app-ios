//
//  CommonJointOperationsSyncMetadataStorageTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
@testable import Tangem

@Suite("CommonJointOperationsSyncMetadataStorage")
struct CommonJointOperationsSyncMetadataStorageTests {
    @Test("A wallet with nothing stored has no cursors and no finished initial sync")
    func emptyStorageHasNoMetadata() async throws {
        let (archiveCursor, deltaCursor, isInitialSyncDone) = try await withInjectedInMemoryAppDatabase {
            let storage = CommonJointOperationsSyncMetadataStorage(userWalletId: Self.firstWalletId)
            return (try await storage.archiveCursor(), try await storage.deltaCursor(), try await storage.isInitialSyncDone())
        }

        #expect(archiveCursor == nil)
        #expect(deltaCursor == nil)
        #expect(!isInitialSyncDone)
    }

    @Test("Each value is set on its own and keeps the others")
    func valuesAreSetIndependently() async throws {
        let (archiveCursor, deltaCursor, isInitialSyncDone) = try await withInjectedInMemoryAppDatabase {
            let storage = CommonJointOperationsSyncMetadataStorage(userWalletId: Self.firstWalletId)
            try await storage.setArchiveCursor("archive-cursor")
            try await storage.setDeltaCursor("delta-cursor")
            try await storage.setIsInitialSyncDone(true)
            return (try await storage.archiveCursor(), try await storage.deltaCursor(), try await storage.isInitialSyncDone())
        }

        #expect(archiveCursor == "archive-cursor")
        #expect(deltaCursor == "delta-cursor")
        #expect(isInitialSyncDone)
    }

    @Test("A cursor set to nil is cleared")
    func cursorSetToNilIsCleared() async throws {
        let archiveCursor = try await withInjectedInMemoryAppDatabase {
            let storage = CommonJointOperationsSyncMetadataStorage(userWalletId: Self.firstWalletId)
            try await storage.setArchiveCursor("archive-cursor")
            try await storage.setArchiveCursor(nil)
            return try await storage.archiveCursor()
        }

        #expect(archiveCursor == nil)
    }

    @Test("Wallets keep their metadata apart")
    func walletsKeepMetadataApart() async throws {
        let (firstCursor, secondCursor, isSecondInitialSyncDone) = try await withInjectedInMemoryAppDatabase {
            let firstStorage = CommonJointOperationsSyncMetadataStorage(userWalletId: Self.firstWalletId)
            let secondStorage = CommonJointOperationsSyncMetadataStorage(userWalletId: Self.secondWalletId)
            try await firstStorage.setDeltaCursor("first-delta-cursor")
            try await firstStorage.setIsInitialSyncDone(true)
            try await secondStorage.setDeltaCursor("second-delta-cursor")
            return (try await firstStorage.deltaCursor(), try await secondStorage.deltaCursor(), try await secondStorage.isInitialSyncDone())
        }

        #expect(firstCursor == "first-delta-cursor")
        #expect(secondCursor == "second-delta-cursor")
        #expect(!isSecondInitialSyncDone)
    }

    @Test("Clearing drops the wallet's metadata and keeps the other wallets' metadata")
    func clearDropsOnlyThisWalletMetadata() async throws {
        let (archiveCursor, deltaCursor, isInitialSyncDone, otherDeltaCursor) = try await withInjectedInMemoryAppDatabase {
            let storage = CommonJointOperationsSyncMetadataStorage(userWalletId: Self.firstWalletId)
            let otherStorage = CommonJointOperationsSyncMetadataStorage(userWalletId: Self.secondWalletId)
            try await storage.setArchiveCursor("archive-cursor")
            try await storage.setDeltaCursor("delta-cursor")
            try await storage.setIsInitialSyncDone(true)
            try await otherStorage.setDeltaCursor("other-delta-cursor")

            try await storage.clear()

            return (
                try await storage.archiveCursor(),
                try await storage.deltaCursor(),
                try await storage.isInitialSyncDone(),
                try await otherStorage.deltaCursor()
            )
        }

        #expect(archiveCursor == nil)
        #expect(deltaCursor == nil)
        #expect(!isInitialSyncDone)
        #expect(otherDeltaCursor == "other-delta-cursor")
    }
}

// MARK: - Helpers

private extension CommonJointOperationsSyncMetadataStorageTests {
    static let firstWalletId = UserWalletId(stringValue: "000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F")
    static let secondWalletId = UserWalletId(stringValue: "1F1E1D1C1B1A191817161514131211100F0E0D0C0B0A09080706050403020100")
}
