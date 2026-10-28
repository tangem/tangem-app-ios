//
//  CommonMobileWalletSocialBackupManagerTests.swift
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

@Suite("CommonMobileWalletSocialBackupManager")
struct CommonMobileWalletSocialBackupManagerTests {
    // MARK: - Create

    @Test("Created backup is written under the fixed social file name and describes the wallet")
    func createBackupWritesTheSocialFile() async throws {
        let env = Self.makeEnvironment()

        let created = try await env.createBackup()

        #expect(env.storage.storedFileNames == [Self.fileName])
        #expect(created.walletId == Self.walletId.stringValue)
        #expect(created.createdAt != nil)
        #expect(created.fileData == env.storage.storedData(fileName: Self.fileName))
    }

    @Test("Created file is a version 1 social backup with an AES-GCM envelope")
    func createBackupWritesAVersion1File() async throws {
        let env = Self.makeEnvironment()

        try await env.createBackup()

        let fileData = try #require(env.storage.storedData(fileName: Self.fileName))
        let json = try #require(JSONSerialization.jsonObject(with: fileData) as? [String: Any])
        #expect(json["version"] as? Int == 1)
        #expect(json["walletId"] as? String == Self.walletId.stringValue)

        let crypto = try #require(json["crypto"] as? [String: Any])
        #expect(crypto["cipher"] as? String == "aes-256-gcm")
    }

    @Test("The plaintext mnemonic never lands in the file")
    func createBackupKeepsTheMnemonicOutOfTheFile() async throws {
        let env = Self.makeEnvironment()

        try await env.createBackup()

        let fileData = try #require(env.storage.storedData(fileName: Self.fileName))
        let fileText = String(decoding: fileData, as: UTF8.self)
        #expect(!fileText.contains(Self.mnemonicWords[0]))
        #expect(!fileText.contains(Self.recoveryKey.lowercasedHexString))
    }

    @Test("A second backup replaces the previous file instead of adding one")
    func createBackupOverwritesThePreviousFile() async throws {
        let env = Self.makeEnvironment()

        let first = try await env.createBackup()
        let second = try await env.createBackup(walletId: Self.otherWalletId)

        #expect(env.storage.storedFileNames == [Self.fileName])
        #expect(first.fileData != second.fileData)
        #expect(env.storage.storedData(fileName: Self.fileName) == second.fileData)
    }

    @Test("Backup is refused when the storage is unavailable and nothing is written")
    func createBackupFailsWhenStorageIsUnavailable() async {
        let env = Self.makeEnvironment()
        env.storage.setAvailable(false)

        await expectStorageUnavailable {
            try await env.createBackup()
        }

        #expect(env.storage.storedFileNames.isEmpty)
    }

    @Test("A recovery key of the wrong length is rejected before anything is written")
    func createBackupRejectsAWrongSizedRecoveryKey() async {
        let env = Self.makeEnvironment()

        await expectFailure(WalletBackupCryptoError.self, matching: \.isInvalidKeyLength) {
            try await env.createBackup(recoveryKey: Data(repeating: 1, count: 16))
        }

        #expect(env.storage.storedFileNames.isEmpty)
    }

    @Test("isStorageAvailable mirrors the storage")
    func isStorageAvailableMirrorsTheStorage() {
        let env = Self.makeEnvironment()
        #expect(env.manager.isStorageAvailable)

        env.storage.setAvailable(false)
        #expect(!env.manager.isStorageAvailable)
    }

    // MARK: - Has / load

    @Test("hasBackup is false on an empty storage and true once a backup is created")
    func hasBackupFollowsTheStoredFile() async throws {
        let env = Self.makeEnvironment()
        #expect(try await env.manager.hasBackup() == false)

        try await env.createBackup()

        #expect(try await env.manager.hasBackup() == true)
    }

    @Test("Foreign files under other names do not count as a social backup")
    func hasBackupIgnoresOtherFiles() async throws {
        let env = Self.makeEnvironment()
        env.storage.seed(Data("foreign".utf8), fileName: "Wallet.backup.json")

        #expect(try await env.manager.hasBackup() == false)
        #expect(try await env.manager.loadBackup() == nil)
    }

    @Test("hasBackup and loadBackup fail when the storage is unavailable")
    func hasAndLoadBackupFailWhenStorageIsUnavailable() async {
        let env = Self.makeEnvironment()
        env.storage.setAvailable(false)

        await expectStorageUnavailable { try await env.manager.hasBackup() }
        await expectStorageUnavailable { try await env.manager.loadBackup() }
    }

    @Test("Loaded backup equals the created one")
    func loadBackupReturnsTheCreatedBackup() async throws {
        let env = Self.makeEnvironment()
        let created = try await env.createBackup()

        let loaded = try #require(try await env.manager.loadBackup())

        #expect(loaded.walletId == created.walletId)
        #expect(loaded.fileData == created.fileData)
        #expect(loaded.createdAt == created.createdAt)
    }

    @Test("A file of an unknown or missing version is rejected", arguments: [
        "not json",
        "{}",
        #"{"version": 99, "walletId": "x"}"#,
        #"{"version": "1", "walletId": "x"}"#,
    ])
    func loadBackupRejectsAnUnsupportedVersion(fileContents: String) async {
        let env = Self.makeEnvironment()
        env.storage.seed(Data(fileContents.utf8), fileName: Self.fileName)

        await expectFailure(WalletBackupDecodingError.self, matching: \.isUnsupportedVersion) {
            try await env.manager.loadBackup()
        }
    }

    @Test("A version 1 file that breaks the schema is reported as a decoding failure")
    func loadBackupRejectsASchemaViolation() async {
        let env = Self.makeEnvironment()
        env.storage.seed(Data(#"{"version": 1, "walletId": "x"}"#.utf8), fileName: Self.fileName)

        await expectFailure(WalletBackupDecodingError.self, matching: \.isDecodingFailed) {
            try await env.manager.loadBackup()
        }
    }

    // MARK: - Import

    @Test("Import with the recovery key restores the mnemonic", arguments: ["", "passphrase"])
    func importBackupRestoresThePayload(passphrase: String) async throws {
        let env = Self.makeEnvironment(passphrase: passphrase)
        let backup = try await env.createBackup()

        let payload = try await env.manager.importBackup(backup, recoveryKey: Self.recoveryKey)

        #expect(payload.mnemonicWords == Self.mnemonicWords)
        #expect(payload.requiresPassphrase == !passphrase.isEmpty)
    }

    @Test("Import of a backup loaded from the storage restores the mnemonic")
    func importBackupWorksOnALoadedBackup() async throws {
        let env = Self.makeEnvironment()
        try await env.createBackup()
        let loaded = try #require(try await env.manager.loadBackup())

        let payload = try await env.manager.importBackup(loaded, recoveryKey: Self.recoveryKey)

        #expect(payload.mnemonicWords == Self.mnemonicWords)
    }

    @Test("Import with another recovery key is rejected")
    func importBackupRejectsAWrongRecoveryKey() async throws {
        let env = Self.makeEnvironment()
        let backup = try await env.createBackup()

        await expectFailure(WalletBackupCryptoError.self, matching: \.isInvalidRecoveryKey) {
            try await env.manager.importBackup(backup, recoveryKey: Self.otherRecoveryKey)
        }
    }

    @Test("Import with a recovery key of the wrong length is rejected")
    func importBackupRejectsAWrongSizedRecoveryKey() async throws {
        let env = Self.makeEnvironment()
        let backup = try await env.createBackup()

        await expectFailure(WalletBackupCryptoError.self, matching: \.isInvalidKeyLength) {
            try await env.manager.importBackup(backup, recoveryKey: Data(repeating: 1, count: 31))
        }
    }

    @Test("Wallet id is authenticated: a file re-labelled for another wallet is rejected")
    func importBackupRejectsARelabelledWalletId() async throws {
        let env = Self.makeEnvironment()
        let backup = try await env.createBackup()
        let relabelled = try Self.replacingWalletId(in: backup, with: Self.otherWalletId.stringValue)

        await expectFailure(WalletBackupCryptoError.self, matching: \.isInvalidRecoveryKey) {
            try await env.manager.importBackup(relabelled, recoveryKey: Self.recoveryKey)
        }
    }

    @Test("A cipher this build cannot run is reported, not silently tried")
    func importBackupRejectsAnUnknownCipher() async throws {
        let env = Self.makeEnvironment()
        let backup = try await env.createBackup()
        let foreignCipher = try Self.replacingCipher(in: backup, with: "chacha20-poly1305")

        let error = try await #require(throws: WalletBackupDecodingError.self) {
            try await env.manager.importBackup(foreignCipher, recoveryKey: Self.recoveryKey)
        }

        guard case .unsupportedAlgorithm("chacha20-poly1305") = error else {
            Issue.record("Expected .unsupportedAlgorithm, got \(error)")
            return
        }
    }

    // MARK: - Delete

    @Test("Delete removes the backup of the given wallet")
    func deleteBackupRemovesTheFile() async throws {
        let env = Self.makeEnvironment()
        try await env.createBackup()

        try await env.manager.deleteBackup(userWalletId: Self.walletId)

        #expect(env.storage.storedFileNames.isEmpty)
        #expect(env.storage.deletedFileNames == [Self.fileName])
        #expect(try await env.manager.hasBackup() == false)
    }

    @Test("Delete refuses to remove another wallet's backup")
    func deleteBackupKeepsAnotherWalletsFile() async throws {
        let env = Self.makeEnvironment()
        try await env.createBackup()

        await expectFailure(WalletBackupStorageError.self, matching: \.isWalletMismatch) {
            try await env.manager.deleteBackup(userWalletId: Self.otherWalletId)
        }

        #expect(env.storage.storedFileNames == [Self.fileName])
    }

    @Test("Delete reports a missing backup")
    func deleteBackupFailsWhenThereIsNoFile() async {
        let env = Self.makeEnvironment()

        await expectFailure(WalletBackupStorageError.self, matching: \.isFileNotFound) {
            try await env.manager.deleteBackup(userWalletId: Self.walletId)
        }
    }

    @Test("Delete fails when the storage is unavailable")
    func deleteBackupFailsWhenStorageIsUnavailable() async {
        let env = Self.makeEnvironment()
        env.storage.setAvailable(false)

        await expectStorageUnavailable {
            try await env.manager.deleteBackup(userWalletId: Self.walletId)
        }
    }
}

// MARK: - Environment

private extension CommonMobileWalletSocialBackupManagerTests {
    struct Environment {
        let manager: CommonMobileWalletSocialBackupManager
        let storage: WalletBackupStorageMock

        @concurrent
        @discardableResult
        func createBackup(
            walletId: UserWalletId = CommonMobileWalletSocialBackupManagerTests.walletId,
            recoveryKey: Data = CommonMobileWalletSocialBackupManagerTests.recoveryKey
        ) async throws -> MobileWalletSocialBackup {
            try await manager.createBackup(
                context: MobileWalletContext(walletID: walletId, authentication: .none),
                userWalletId: walletId,
                recoveryKey: recoveryKey
            )
        }
    }

    static func makeEnvironment(passphrase: String = "") -> Environment {
        let storage = WalletBackupStorageMock()
        let manager = CommonMobileWalletSocialBackupManager(
            mobileWalletSdk: MobileWalletSdkMock(mnemonicWords: mnemonicWords, passphrase: passphrase),
            storage: storage,
            backupResolver: CommonSocialWalletBackupFormatResolver()
        )

        return Environment(manager: manager, storage: storage)
    }

    static let fileName = "social-backup.json"
    static let mnemonicWords = [
        "abandon", "abandon", "abandon", "abandon", "abandon", "abandon",
        "abandon", "abandon", "abandon", "abandon", "abandon", "about",
    ]
    static let recoveryKey = Data((0 ..< 32).map(UInt8.init))
    static let otherRecoveryKey = Data((0 ..< 32).map { UInt8(255 - $0) })
    static let walletId = UserWalletId(value: Data([0xAA, 0xBB, 0xCC, 0xDD]))
    static let otherWalletId = UserWalletId(value: Data([0x11, 0x22, 0x33, 0x44]))

    static func replacingWalletId(in backup: MobileWalletSocialBackup, with walletId: String) throws -> MobileWalletSocialBackup {
        try replacingField(in: backup) { json in
            json["walletId"] = walletId
        }
    }

    static func replacingCipher(in backup: MobileWalletSocialBackup, with cipher: String) throws -> MobileWalletSocialBackup {
        try replacingField(in: backup) { json in
            var crypto = try #require(json["crypto"] as? [String: Any])
            crypto["cipher"] = cipher
            json["crypto"] = crypto
        }
    }

    static func replacingField(
        in backup: MobileWalletSocialBackup,
        _ mutate: (inout [String: Any]) throws -> Void
    ) throws -> MobileWalletSocialBackup {
        var json = try #require(JSONSerialization.jsonObject(with: backup.fileData) as? [String: Any])
        try mutate(&json)
        let fileData = try JSONSerialization.data(withJSONObject: json)

        return MobileWalletSocialBackup(walletId: backup.walletId, createdAt: backup.createdAt, fileData: fileData)
    }
}
