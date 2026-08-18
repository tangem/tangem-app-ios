//
//  MobileWalletBackupManager.swift
//  TangemMobileWalletBackup
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemMobileWalletSdk

public protocol MobileWalletBackupManager {
    var isStorageAvailable: Bool { get }

    /// Creates an encrypted backup of a single mobile wallet and returns it
    /// exactly as `loadBackups` would later see it.
    ///
    /// The operation is all-or-nothing: it either returns a result after the file has been
    /// written to the backup storage, or throws leaving no partial state behind.
    @discardableResult
    func createBackup(
        context: MobileWalletContext,
        walletName: String,
        walletId: UserWalletId,
        password: String
    ) async throws -> MobileWalletBackup

    /// Backups available for import.
    ///
    /// Files that are not valid Tangem backups — no or unsupported `version`, schema
    /// mismatch, unreadable contents — are skipped with the reason logged: one foreign or
    /// corrupted file next to a valid backup must not fail the whole listing.
    func loadBackups() async throws -> [MobileWalletBackup]

    /// Load backup for `UserWalletId`, or `nil` when the storage holds none.
    func loadBackup(walletId: UserWalletId) async throws -> MobileWalletBackup?

    /// Decrypts the backup with the user's password and returns the secret payload.
    ///
    /// Throws `WalletBackupCryptoError.invalidPassword` when the password is wrong or the
    /// file was tampered with — the two are indistinguishable for an AEAD cipher.
    func importBackup(_ backup: MobileWalletBackup, password: String) async throws -> any WalletBackupPayload

    /// Deletes a single backup previously returned by `loadBackups`.
    ///
    /// Throws `WalletBackupStorageError.fileNotFound` when the file no longer exists —
    /// e.g. the backup was removed from another device.
    func deleteBackup(_ backup: MobileWalletBackup) async throws

    /// Deletes every backup file of the given `UserWalletId`, stopping at the first failure.
    ///
    /// Throws `WalletBackupStorageError.fileNotFound` when there is nothing to delete —
    /// e.g. the backup was removed from another device.
    func deleteBackups(walletId: UserWalletId) async throws
}

public final class CommonMobileWalletBackupManager: MobileWalletBackupManager {
    private let mobileWalletSdk: MobileWalletSdk
    private let storage: WalletBackupStorage
    private let backupResolver: WalletBackupFormatResolver

    public convenience init(destination: MobileWalletBackupDestination) {
        let storage: WalletBackupStorage = switch destination {
        case .iCloud: ICloudBackupStorage()
        }

        self.init(
            mobileWalletSdk: CommonMobileWalletSdk(),
            storage: storage,
            backupResolver: CommonWalletBackupFormatResolver()
        )
    }

    init(
        mobileWalletSdk: MobileWalletSdk,
        storage: WalletBackupStorage,
        backupResolver: WalletBackupFormatResolver
    ) {
        self.mobileWalletSdk = mobileWalletSdk
        self.storage = storage
        self.backupResolver = backupResolver
    }

    public var isStorageAvailable: Bool {
        storage.isAvailable
    }

    @discardableResult
    public func createBackup(
        context: MobileWalletContext,
        walletName: String,
        walletId: UserWalletId,
        password: String
    ) async throws -> MobileWalletBackup {
        guard storage.isAvailable else {
            throw WalletBackupStorageError.storageUnavailable
        }

        let mnemonicWords = try mobileWalletSdk.exportMnemonic(context: context)
        let passphrase = try mobileWalletSdk.exportPassphrase(context: context)
        let payload = CommonWalletBackupPayload(mnemonicWords: mnemonicWords, passphrase: passphrase)

        let format = WalletBackupFormatVersion.current.resolve(backupResolver)
        let file = try format.makeFile(
            payload: payload,
            walletName: walletName,
            walletId: walletId.stringValue,
            password: password
        )
        let fileData = try encode(file)

        let existingFileNames = try await storage.files().map(\.name)
        let fileName = makeFileName(walletName: walletName, existingFileNames: existingFileNames)
        let backup = try format.backup(from: fileData, fileName: fileName)

        try await storage.write(fileData, fileName: fileName)

        return backup
    }

    public func loadBackups() async throws -> [MobileWalletBackup] {
        let backupFiles = try await loadBackupFiles()

        var backups: [MobileWalletBackup] = []
        for file in backupFiles {
            if let backup = await loadBackup(file: file) {
                backups.append(backup)
            }
        }

        return backups
    }

    public func loadBackup(walletId: UserWalletId) async throws -> MobileWalletBackup? {
        let backupFiles = try await loadBackupFiles()

        for file in backupFiles {
            guard
                let backup = await loadBackup(file: file),
                backup.metadata.walletId == walletId.stringValue
            else {
                continue
            }

            return backup
        }

        return nil
    }

    public func importBackup(_ backup: MobileWalletBackup, password: String) async throws -> any WalletBackupPayload {
        guard let version = WalletBackupFormatVersion(fileData: backup.fileData) else {
            throw WalletBackupDecodingError.unsupportedVersion
        }

        let format = version.resolve(backupResolver)
        return try format.payload(from: backup.fileData, password: password)
    }

    public func deleteBackup(_ backup: MobileWalletBackup) async throws {
        let backupFiles = try await loadBackupFiles()

        // The file name is not a stable identity: the file under it may have been replaced
        // from another device after the backup was loaded. The backup's own id is verified
        // in the file contents before anything is deleted.
        for file in backupFiles {
            guard
                let candidate = await loadBackup(file: file),
                candidate.id == backup.id
            else {
                continue
            }

            try await storage.delete(file: file)
            return
        }

        throw WalletBackupStorageError.fileNotFound
    }

    public func deleteBackups(walletId: UserWalletId) async throws {
        let backupFiles = try await loadBackupFiles()

        guard backupFiles.isNotEmpty else {
            throw WalletBackupStorageError.fileNotFound
        }

        var foundWalletBackup = false

        for file in backupFiles {
            guard
                let backup = await loadBackup(file: file),
                backup.metadata.walletId == walletId.stringValue
            else {
                continue
            }

            try await storage.delete(file: file)
            foundWalletBackup = true
        }

        guard foundWalletBackup else {
            throw WalletBackupStorageError.fileNotFound
        }
    }
}

// MARK: - Private implementation

private extension CommonMobileWalletBackupManager {
    func loadBackupFiles() async throws -> [WalletBackupStorageFile] {
        guard storage.isAvailable else {
            throw WalletBackupStorageError.storageUnavailable
        }

        return try await storage.files()
            .filter { $0.name.hasSuffix(Constants.fileNameSuffix) }
    }

    func loadBackup(file: WalletBackupStorageFile) async -> MobileWalletBackup? {
        do {
            let fileData = try await storage.read(file: file)

            guard let version = WalletBackupFormatVersion(fileData: fileData) else {
                WalletBackupLogger.debug("Skipped a file with no supported backup version")
                return nil
            }

            let format = version.resolve(backupResolver)
            return try format.backup(from: fileData, fileName: file.name)
        } catch {
            WalletBackupLogger.error("Skipped an unreadable backup file", error: error)
            return nil
        }
    }

    func encode(_ file: some Encodable) throws -> Data {
        do {
            return try WalletBackupJSONCodec.encode(file)
        } catch {
            throw WalletBackupEncodingError.encodingFailed(error)
        }
    }

    /// Builds the user-visible file name: `<wallet name>.backup.json`, or
    /// `<wallet name> (N).backup.json` with the smallest free `N` when the name is taken.
    func makeFileName(walletName: String, existingFileNames: [String]) -> String {
        let baseName = sanitizedBaseName(from: walletName)

        // Case-insensitive: iCloud Drive and APFS on macOS treat `Wallet` and `wallet`
        // as the same file, colliding on sync even though iOS distinguishes them locally.
        let takenNames = Set(existingFileNames.map { $0.lowercased() })

        let preferredFileName = "\(baseName)\(Constants.fileNameSuffix)"
        guard takenNames.contains(preferredFileName.lowercased()) else {
            return preferredFileName
        }

        return smallestNumberedFileName(baseName: baseName, takenNames: takenNames)
    }

    func sanitizedBaseName(from walletName: String) -> String {
        let name = walletName
            .components(separatedBy: Constants.forbiddenFileNameCharacters)
            .joined()
            .trimmingCharacters(in: Constants.trimmedFileNameEdgeCharacters)

        return name.isEmpty ? Constants.fallbackWalletName : name
    }

    /// `<baseName> (N).backup.json` with the smallest free `N`; numbering starts at 1.
    /// Terminates because `takenNames` is finite: it can occupy at most `count` numbers,
    /// so the search never goes past `count + 1`.
    func smallestNumberedFileName(baseName: String, takenNames: Set<String>) -> String {
        var copyNumber = Constants.firstFileCopyNumber
        var candidate: String { "\(baseName) (\(copyNumber))\(Constants.fileNameSuffix)" }

        while takenNames.contains(candidate.lowercased()) {
            copyNumber += 1
        }

        return candidate
    }
}

// MARK: - Constants

private extension CommonMobileWalletBackupManager {
    enum Constants {
        static let fallbackWalletName = "Wallet"
        static let fileNameSuffix = ".backup.json"
        static let firstFileCopyNumber: Int = 1

        /// Characters invalid on at least one file system the backup file can reach:
        /// `/` on APFS, `:` in the Finder (HFS legacy), `\ / : * ? " < > |` in iCloud
        /// for Windows, plus `%` to avoid URL-encoding surprises. Removed anywhere in the name.
        static let forbiddenFileNameCharacters = CharacterSet(charactersIn: "/\\:?%*|\"<>")

        /// Stripped from the edges of the name only: a leading dot would make the file
        /// hidden and not synced by iCloud Drive, trailing dots and whitespace are
        /// invalid on Windows. Both are legal in the middle of the name.
        static let trimmedFileNameEdgeCharacters = CharacterSet.whitespacesAndNewlines
            .union(CharacterSet(charactersIn: "."))
    }
}
