//
//  WalletBackupStorage.swift
//  TangemMobileWalletBackup
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol WalletBackupStorage {
    var isAvailable: Bool { get }

    /// All files in the backup folder, including ones not yet downloaded from the cloud.
    func files() async throws -> [WalletBackupStorageFile]

    /// Contents of a file, downloading it from the cloud first if needed.
    func read(file: WalletBackupStorageFile) async throws -> Data

    func write(_ data: Data, fileName: String) async throws
}

/// Stores backup files in the `Documents` folder of the app's ubiquity container.
final class ICloudBackupStorage: WalletBackupStorage, Sendable {
    /// `url(forUbiquityContainerIdentifier:)` and `NSFileCoordinator` perform blocking I/O —
    /// potentially long while iCloud holds the file — which must not occupy a cooperative-pool
    /// thread, hence a plain dispatch queue.
    private let queue = DispatchQueue(label: "com.tangem.ICloudBackupStorage.storage")

    /// System-defined subdirectory name: only the contents of `Documents` are surfaced
    /// in iCloud Drive, the rest of the container stays app-private. There is no API
    /// constant for it.
    private let documentsPath = "Documents"

    var isAvailable: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }

    func files() async throws -> [WalletBackupStorageFile] {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do {
                    continuation.resume(returning: try self.list())
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func read(file: WalletBackupStorageFile) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do {
                    continuation.resume(returning: try self.readData(file: file))
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func write(_ data: Data, fileName: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do {
                    try self.writeData(data, fileName: fileName)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

// MARK: - Private implementation

private extension ICloudBackupStorage {
    func writeData(_ data: Data, fileName: String) throws {
        let fileManager = FileManager()
        let documentsURL = try documentsDirectoryURL(fileManager: fileManager)
        let fileURL = documentsURL.appendingPathComponent(fileName, isDirectory: false)

        do {
            try fileManager.createDirectory(at: documentsURL, withIntermediateDirectories: true)
        } catch {
            throw WalletBackupStorageError.writeFailed(error)
        }

        var coordinationError: NSError?
        var writeError: Error?
        let coordinator = NSFileCoordinator()

        coordinator.coordinate(writingItemAt: fileURL, options: .forReplacing, error: &coordinationError) { url in
            do {
                try data.write(to: url, options: .atomic)
            } catch {
                writeError = error
            }
        }

        if let error = coordinationError ?? writeError {
            throw WalletBackupStorageError.writeFailed(error)
        }
    }

    func readData(file: WalletBackupStorageFile) throws -> Data {
        let fileManager = FileManager()

        // A file listed via its `.icloud` placeholder has no local content yet; request the
        // download explicitly — the coordinated read below then blocks until the data arrives.
        // Failure is ignored: for an already-local file there is nothing to download, and a
        // genuinely unreachable file surfaces as a read error right after.
        try? fileManager.startDownloadingUbiquitousItem(at: file.url)

        var coordinationError: NSError?
        var readResult: Result<Data, Error> = .failure(WalletBackupStorageError.storageUnavailable)
        let coordinator = NSFileCoordinator()

        coordinator.coordinate(readingItemAt: file.url, options: [], error: &coordinationError) { url in
            readResult = Result { try Data(contentsOf: url) }
        }

        if let coordinationError {
            throw WalletBackupStorageError.readFailed(coordinationError)
        }

        do {
            return try readResult.get()
        } catch {
            throw WalletBackupStorageError.readFailed(error)
        }
    }

    func list() throws -> [WalletBackupStorageFile] {
        let fileManager = FileManager()
        let documentsURL = try documentsDirectoryURL(fileManager: fileManager)

        guard fileManager.fileExists(atPath: documentsURL.path) else {
            return []
        }

        do {
            return try fileManager.contentsOfDirectory(atPath: documentsURL.path)
                .map(normalizedFileName)
                .map { name in
                    WalletBackupStorageFile(
                        name: name,
                        url: documentsURL.appendingPathComponent(name, isDirectory: false)
                    )
                }
        } catch {
            throw WalletBackupStorageError.readFailed(error)
        }
    }

    func documentsDirectoryURL(fileManager: FileManager) throws -> URL {
        // `nil` means the first container from the app's
        // `com.apple.developer.icloud-container-identifiers` entitlement.
        guard let containerURL = fileManager.url(forUbiquityContainerIdentifier: nil) else {
            throw WalletBackupStorageError.storageUnavailable
        }

        return containerURL.appendingPathComponent(documentsPath, isDirectory: true)
    }

    /// Files that exist in the cloud but are not downloaded to this device are enumerated
    /// as `.<name>.icloud` placeholders — unwrap them back to the real file name.
    func normalizedFileName(_ name: String) -> String {
        guard name.hasPrefix("."), name.hasSuffix(Constants.icloudPlaceholderSuffix) else {
            return name
        }

        return String(name.dropFirst().dropLast(Constants.icloudPlaceholderSuffix.count))
    }
}

// MARK: - Constants

private extension ICloudBackupStorage {
    enum Constants {
        static let icloudPlaceholderSuffix = ".icloud"
    }
}
