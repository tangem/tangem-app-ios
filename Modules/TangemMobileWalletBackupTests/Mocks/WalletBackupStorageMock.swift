//
//  WalletBackupStorageMock.swift
//  TangemMobileWalletBackupTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
@testable import TangemMobileWalletBackup

/// In-memory stand-in for the iCloud storage. File names are unique keys,
/// like paths in a real folder; URLs are synthesized and never dereferenced.
final class WalletBackupStorageMock: WalletBackupStorage, Sendable {
    private struct State {
        var isAvailable = true
        var fileContents: [String: Data] = [:]
        var deletedFileNames: [String] = []
    }

    private let state = OSAllocatedUnfairLock(initialState: State())

    var isAvailable: Bool {
        state.withLock { $0.isAvailable }
    }

    func files() async throws -> [WalletBackupStorageFile] {
        state.withLock { state in
            state.fileContents.keys.sorted().map(Self.makeFile)
        }
    }

    func read(file: WalletBackupStorageFile) async throws -> Data {
        try state.withLock { state in
            guard let data = state.fileContents[file.name] else {
                throw WalletBackupStorageError.readFailed(CocoaError(.fileReadNoSuchFile))
            }

            return data
        }
    }

    func write(_ data: Data, fileName: String) async throws {
        state.withLock { state in
            state.fileContents[fileName] = data
        }
    }

    func delete(file: WalletBackupStorageFile) async throws {
        try state.withLock { state in
            guard state.fileContents.removeValue(forKey: file.name) != nil else {
                throw WalletBackupStorageError.deleteFailed(CocoaError(.fileNoSuchFile))
            }

            state.deletedFileNames.append(file.name)
        }
    }

    // MARK: - Test control and introspection

    func setAvailable(_ isAvailable: Bool) {
        state.withLock { $0.isAvailable = isAvailable }
    }

    /// Seeds a file bypassing the storage API, as if it appeared from another device.
    func seed(_ data: Data, fileName: String) {
        state.withLock { $0.fileContents[fileName] = data }
    }

    var storedFileNames: [String] {
        state.withLock { $0.fileContents.keys.sorted() }
    }

    var deletedFileNames: [String] {
        state.withLock { $0.deletedFileNames }
    }

    func storedData(fileName: String) -> Data? {
        state.withLock { $0.fileContents[fileName] }
    }

    private static func makeFile(name: String) -> WalletBackupStorageFile {
        WalletBackupStorageFile(
            name: name,
            url: URL(fileURLWithPath: "/mock-storage/\(name)", isDirectory: false)
        )
    }
}
