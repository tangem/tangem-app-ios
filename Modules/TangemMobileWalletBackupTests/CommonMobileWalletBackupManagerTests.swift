//
//  CommonMobileWalletBackupManagerTests.swift
//  TangemMobileWalletBackupTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
@testable import TangemMobileWalletBackup
@testable import TangemMobileWalletSdk

@Suite("CommonMobileWalletBackupManager")
struct CommonMobileWalletBackupManagerTests {
    // MARK: - Create

    @Test("Created backup is stored and equals what loadBackups later sees")
    func createBackupStoresFileAndMatchesLoadBackups() async throws {
        let env = Self.makeEnvironment()

        let created = try await env.manager.createBackup(
            context: Self.context,
            walletName: "Wallet",
            walletId: Self.walletId,
            password: Self.password
        )

        #expect(env.storage.storedFileNames == ["Wallet.backup.json"])
        #expect(created.metadata.fileName == "Wallet.backup.json")
        #expect(created.metadata.walletName == "Wallet")
        #expect(created.metadata.walletId == Self.walletId.stringValue)
        #expect(created.metadata.createdAt != nil)

        let loaded = try await env.manager.loadBackups()
        try #require(loaded.count == 1)
        #expect(loaded[0].id == created.id)
        #expect(loaded[0].fileData == created.fileData)
    }

    @Test("File name collision picks the smallest free number")
    func createBackupPicksSmallestFreeNumberedName() async throws {
        let env = Self.makeEnvironment()
        env.storage.seed(Data("foreign".utf8), fileName: "Wallet.backup.json")
        env.storage.seed(Data("foreign".utf8), fileName: "Wallet (2).backup.json")

        let created = try await env.manager.createBackup(
            context: Self.context,
            walletName: "Wallet",
            walletId: Self.walletId,
            password: Self.password
        )

        #expect(created.metadata.fileName == "Wallet (1).backup.json")
    }

    @Test("File name collision is detected case-insensitively")
    func createBackupTreatsNamesCaseInsensitively() async throws {
        let env = Self.makeEnvironment()
        env.storage.seed(Data("foreign".utf8), fileName: "wallet.backup.json")

        let created = try await env.manager.createBackup(
            context: Self.context,
            walletName: "Wallet",
            walletId: Self.walletId,
            password: Self.password
        )

        #expect(created.metadata.fileName == "Wallet (1).backup.json")
    }

    @Test("Existing backup of the same wallet is overwritten, keeping its file name")
    func createBackupOverwritesExistingBackupOfSameWallet() async throws {
        let env = Self.makeEnvironment()

        let original = try await env.manager.createBackup(
            context: Self.context,
            walletName: "Wallet",
            walletId: Self.walletId,
            password: Self.password
        )

        let replacement = try await env.manager.createBackup(
            context: Self.context,
            walletName: "Renamed",
            walletId: Self.walletId,
            password: Self.password
        )

        #expect(env.storage.storedFileNames == ["Wallet.backup.json"])
        #expect(replacement.metadata.fileName == "Wallet.backup.json")
        #expect(replacement.metadata.walletName == "Renamed")

        let loaded = try await env.manager.loadBackups()
        try #require(loaded.count == 1)
        #expect(loaded[0].id == replacement.id)
        #expect(loaded[0].id != original.id)
    }

    @Test("Only the first found backup of the wallet is overwritten")
    func createBackupOverwritesOnlyFirstBackupOfWallet() async throws {
        let env = Self.makeEnvironment()

        let original = try await env.manager.createBackup(
            context: Self.context,
            walletName: "Wallet",
            walletId: Self.walletId,
            password: Self.password
        )
        env.storage.seed(original.fileData, fileName: "Wallet (1).backup.json")

        let replacement = try await env.manager.createBackup(
            context: Self.context,
            walletName: "Wallet",
            walletId: Self.walletId,
            password: Self.password
        )

        // The mock lists files in lexicographic order, so `Wallet (1)` comes first.
        #expect(replacement.metadata.fileName == "Wallet (1).backup.json")
        #expect(env.storage.storedFileNames == ["Wallet (1).backup.json", "Wallet.backup.json"])
        #expect(env.storage.storedData(fileName: "Wallet.backup.json") == original.fileData)
        #expect(env.storage.storedData(fileName: "Wallet (1).backup.json") == replacement.fileData)
    }

    @Test("Backup of a different wallet under the same name is not overwritten")
    func createBackupKeepsBackupOfDifferentWalletWithSameName() async throws {
        let env = Self.makeEnvironment()

        let foreign = try await env.manager.createBackup(
            context: Self.context,
            walletName: "Wallet",
            walletId: Self.otherWalletId,
            password: Self.password
        )

        let created = try await env.manager.createBackup(
            context: Self.context,
            walletName: "Wallet",
            walletId: Self.walletId,
            password: Self.password
        )

        #expect(created.metadata.fileName == "Wallet (1).backup.json")
        #expect(env.storage.storedFileNames == ["Wallet (1).backup.json", "Wallet.backup.json"])
        #expect(env.storage.storedData(fileName: "Wallet.backup.json") == foreign.fileData)
    }

    @Test(
        "Wallet name is sanitized for the file name",
        arguments: [
            ("My/Wal:let?", "MyWallet.backup.json"),
            ("  Wallet  ", "Wallet.backup.json"),
            ("..Wallet..", "Wallet.backup.json"),
            ("My.Wallet", "My.Wallet.backup.json"),
            ("///", "Wallet.backup.json"),
            ("", "Wallet.backup.json"),
        ]
    )
    func createBackupSanitizesWalletName(walletName: String, expectedFileName: String) async throws {
        let env = Self.makeEnvironment()

        let created = try await env.manager.createBackup(
            context: Self.context,
            walletName: walletName,
            walletId: Self.walletId,
            password: Self.password
        )

        #expect(created.metadata.fileName == expectedFileName)
        // The user-visible wallet name inside the file stays as given — only the file name is sanitized.
        #expect(created.metadata.walletName == walletName)
    }

    @Test("Unavailable storage fails the creation before anything is written")
    func createBackupThrowsWhenStorageUnavailable() async throws {
        let env = Self.makeEnvironment()
        env.storage.setAvailable(false)

        await expectStorageUnavailable {
            try await env.manager.createBackup(
                context: Self.context,
                walletName: "Wallet",
                walletId: Self.walletId,
                password: Self.password
            )
        }

        #expect(env.storage.storedFileNames.isEmpty)
    }

    @Test(
        "Backup round-trips the mnemonic and the passphrase requirement",
        arguments: [
            ("", false),
            ("secret passphrase", true),
        ]
    )
    func createBackupStoresPassphraseRequirement(passphrase: String, requiresPassphrase: Bool) async throws {
        let env = Self.makeEnvironment(passphrase: passphrase)

        let created = try await env.manager.createBackup(
            context: Self.context,
            walletName: "Wallet",
            walletId: Self.walletId,
            password: Self.password
        )

        let payload = try await env.manager.importBackup(created, password: Self.password)

        #expect(payload.mnemonicWords == Self.mnemonicWords)
        #expect(payload.requiresPassphrase == requiresPassphrase)
    }

    // MARK: - Load

    @Test("Foreign and unreadable files are skipped, valid backups survive")
    func loadBackupsSkipsForeignAndCorruptedFiles() async throws {
        let env = Self.makeEnvironment()

        let created = try await env.manager.createBackup(
            context: Self.context,
            walletName: "Wallet",
            walletId: Self.walletId,
            password: Self.password
        )

        env.storage.seed(Data("just a note".utf8), fileName: "notes.txt")
        env.storage.seed(Data("not json at all".utf8), fileName: "corrupted.backup.json")
        env.storage.seed(Data(#"{"version": 99}"#.utf8), fileName: "from-the-future.backup.json")

        let loaded = try await env.manager.loadBackups()

        try #require(loaded.count == 1)
        #expect(loaded[0].id == created.id)
    }

    @Test("Unavailable storage fails the listing")
    func loadBackupsThrowsWhenStorageUnavailable() async throws {
        let env = Self.makeEnvironment()
        env.storage.setAvailable(false)

        await expectStorageUnavailable {
            try await env.manager.loadBackups()
        }
    }

    @Test("Backup is found by its wallet id")
    func loadBackupByWalletId() async throws {
        let env = Self.makeEnvironment()

        let created = try await env.manager.createBackup(
            context: Self.context,
            walletName: "Wallet",
            walletId: Self.walletId,
            password: Self.password
        )

        let found = try await env.manager.loadBackup(walletId: Self.walletId)
        #expect(found?.id == created.id)

        let missing = try await env.manager.loadBackup(walletId: Self.otherWalletId)
        #expect(missing == nil)
    }

    // MARK: - Import

    @Test("Wrong password surfaces as invalidPassword")
    func importBackupWrongPasswordThrowsInvalidPassword() async throws {
        let env = Self.makeEnvironment()

        let created = try await env.manager.createBackup(
            context: Self.context,
            walletName: "Wallet",
            walletId: Self.walletId,
            password: Self.password
        )

        await #expect {
            try await env.manager.importBackup(created, password: "Wrong#Password1")
        } throws: { error in
            guard case WalletBackupCryptoError.invalidPassword = error else {
                return false
            }
            return true
        }
    }

    @Test("Backup of an unknown format version is refused")
    func importBackupUnknownVersionThrowsUnsupportedVersion() async throws {
        let env = Self.makeEnvironment()
        let backup = MobileWalletBackup(
            id: "some-id",
            metadata: WalletBackupMetadata(
                fileName: "Wallet.backup.json",
                walletName: "Wallet",
                walletId: Self.walletId.stringValue,
                createdAt: nil
            ),
            fileData: Data(#"{"version": 99}"#.utf8)
        )

        await #expect {
            try await env.manager.importBackup(backup, password: Self.password)
        } throws: { error in
            guard case WalletBackupDecodingError.unsupportedVersion = error else {
                return false
            }
            return true
        }
    }

    // MARK: - Delete single backup

    @Test("Deleting a backup removes its file only")
    func deleteBackupRemovesOnlyThatFile() async throws {
        let env = Self.makeEnvironment()

        let first = try await env.manager.createBackup(
            context: Self.context,
            walletName: "First",
            walletId: Self.walletId,
            password: Self.password
        )
        try await env.manager.createBackup(
            context: Self.context,
            walletName: "Second",
            walletId: Self.otherWalletId,
            password: Self.password
        )

        try await env.manager.deleteBackup(first)

        #expect(env.storage.storedFileNames == ["Second.backup.json"])

        await expectFileNotFound {
            try await env.manager.deleteBackup(first)
        }
    }

    @Test("A file replaced under the same name is not deleted by a stale backup")
    func deleteBackupIgnoresReplacedFileWithSameName() async throws {
        let replacementEnv = Self.makeEnvironment()
        let replacement = try await replacementEnv.manager.createBackup(
            context: Self.context,
            walletName: "Wallet",
            walletId: Self.walletId,
            password: Self.password
        )

        let env = Self.makeEnvironment()
        let stale = try await env.manager.createBackup(
            context: Self.context,
            walletName: "Wallet",
            walletId: Self.walletId,
            password: Self.password
        )

        // Another device replaced the file: same name, same wallet, different backup id.
        env.storage.seed(replacement.fileData, fileName: "Wallet.backup.json")

        await expectFileNotFound {
            try await env.manager.deleteBackup(stale)
        }

        #expect(env.storage.storedFileNames == ["Wallet.backup.json"])
        #expect(env.storage.deletedFileNames.isEmpty)
    }

    // MARK: - Delete all wallet backups

    @Test("Deleting by wallet id removes every file of that wallet and nothing else")
    func deleteBackupsRemovesAllFilesOfWallet() async throws {
        let env = Self.makeEnvironment()

        let created = try await env.manager.createBackup(
            context: Self.context,
            walletName: "Wallet",
            walletId: Self.walletId,
            password: Self.password
        )
        // A second file of the same wallet, as if left behind by an older app version.
        env.storage.seed(created.fileData, fileName: "Wallet (1).backup.json")
        try await env.manager.createBackup(
            context: Self.context,
            walletName: "Other",
            walletId: Self.otherWalletId,
            password: Self.password
        )

        try await env.manager.deleteBackups(walletId: Self.walletId)

        #expect(env.storage.storedFileNames == ["Other.backup.json"])
    }

    @Test("Deleting by wallet id with nothing to delete is an error")
    func deleteBackupsThrowsWhenNoFilesMatch() async throws {
        let env = Self.makeEnvironment()

        await expectFileNotFound {
            try await env.manager.deleteBackups(walletId: Self.walletId)
        }

        try await env.manager.createBackup(
            context: Self.context,
            walletName: "Other",
            walletId: Self.otherWalletId,
            password: Self.password
        )

        await expectFileNotFound {
            try await env.manager.deleteBackups(walletId: Self.walletId)
        }

        #expect(env.storage.storedFileNames == ["Other.backup.json"])
    }
}

// MARK: - Environment and fixtures

private extension CommonMobileWalletBackupManagerTests {
    struct Environment {
        let manager: CommonMobileWalletBackupManager
        let storage: WalletBackupStorageMock
    }

    static func makeEnvironment(passphrase: String = "") -> Environment {
        let storage = WalletBackupStorageMock()
        let manager = CommonMobileWalletBackupManager(
            mobileWalletSdk: MobileWalletSdkMock(mnemonicWords: mnemonicWords, passphrase: passphrase),
            storage: storage,
            backupResolver: CommonWalletBackupFormatResolver()
        )

        return Environment(manager: manager, storage: storage)
    }

    static let mnemonicWords = [
        "abandon", "abandon", "abandon", "abandon", "abandon", "abandon",
        "abandon", "abandon", "abandon", "abandon", "abandon", "about",
    ]
    static let password = "Backup#Password1"
    static let walletId = UserWalletId(value: Data([0xAA, 0xBB, 0xCC, 0xDD]))
    static let otherWalletId = UserWalletId(value: Data([0x11, 0x22, 0x33, 0x44]))
    static var context: MobileWalletContext {
        MobileWalletContext(walletID: walletId, authentication: .none)
    }

    func expectStorageUnavailable<T>(
        sourceLocation: SourceLocation = #_sourceLocation,
        _ operation: () async throws -> T
    ) async {
        do {
            _ = try await operation()
            Issue.record("Expected storageUnavailable, but the operation succeeded", sourceLocation: sourceLocation)
        } catch WalletBackupStorageError.storageUnavailable {
            // Expected.
        } catch {
            Issue.record("Expected storageUnavailable, got \(error)", sourceLocation: sourceLocation)
        }
    }

    func expectFileNotFound(
        sourceLocation: SourceLocation = #_sourceLocation,
        _ operation: () async throws -> Void
    ) async {
        do {
            try await operation()
            Issue.record("Expected fileNotFound, but the operation succeeded", sourceLocation: sourceLocation)
        } catch WalletBackupStorageError.fileNotFound {
            // Expected.
        } catch {
            Issue.record("Expected fileNotFound, got \(error)", sourceLocation: sourceLocation)
        }
    }
}
