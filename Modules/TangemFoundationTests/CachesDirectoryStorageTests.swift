//
//  CachesDirectoryStorageTests.swift
//  TangemFoundationTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemFoundation

@Suite("CachesDirectoryStorage")
struct CachesDirectoryStorageTests {
    private struct TestFile: CachesDirectoryStorage.File {
        let name: String
    }

    @Test("Async value throws fileNotFound when nothing was stored")
    func asyncReadMissingFile() async {
        let name = Self.uniqueName()
        defer { Self.removeCacheFile(named: name) }
        let storage = CachesDirectoryStorage(file: TestFile(name: name))

        await #expect(throws: CachesDirectoryStorage.StorageError.self) {
            let _: [String: Int] = try await storage.value()
        }
    }

    @Test("Async value returns the previously stored value")
    func asyncReadReturnsStoredValue() async throws {
        let name = Self.uniqueName()
        defer { Self.removeCacheFile(named: name) }
        let storage = CachesDirectoryStorage(file: TestFile(name: name))

        let value = ["a": 1, "b": 2]
        try storage.storeAndWait(value: value)

        let loaded: [String: Int] = try await storage.value()
        #expect(loaded == value)
    }
}

private extension CachesDirectoryStorageTests {
    static func uniqueName() -> String {
        "caches_directory_storage_unit_test_\(UUID().uuidString)"
    }

    static func removeCacheFile(named name: String) {
        let url = FileManager.default
            .urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(name)
            .appendingPathExtension("json")

        try? FileManager.default.removeItem(at: url)
    }
}
