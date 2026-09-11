//
//  WalletBackupFormatV1FileTests.swift
//  TangemMobileWalletBackupTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemMobileWalletBackup

@Suite("WalletBackupFormatV1 file handling")
struct WalletBackupFormatV1FileTests {
    private let format = WalletBackupFormatV1()

    // MARK: - Listing metadata

    @Test("A listed backup carries the file's identity and metadata without a password")
    func backupParsesFileMetadata() throws {
        let file = try Self.makeFile()
        let fileData = try WalletBackupJSONCodec.encode(file)

        let backup = try format.backup(from: fileData, fileName: "Wallet.backup.json")

        #expect(backup.id == file.id)
        #expect(backup.metadata.fileName == "Wallet.backup.json")
        #expect(backup.metadata.walletName == file.name)
        #expect(backup.metadata.walletId == file.walletId)
        #expect(backup.metadata.createdAt == ISO8601DateFormatter().date(from: file.createdAt))
        #expect(backup.metadata.createdAt != nil)
        #expect(backup.fileData == fileData)
    }

    @Test("A malformed createdAt hides the date, not the backup")
    func backupToleratesInvalidCreatedAt() throws {
        let fileData = try Self.makeFileData()
        let mutated = try Self.mutatingTopLevelField(fileData, key: "createdAt", value: "not-a-date")

        let backup = try format.backup(from: mutated, fileName: "Wallet.backup.json")

        #expect(backup.metadata.createdAt == nil)
        #expect(backup.metadata.walletName == "Wallet")
    }

    @Test("A file that is not a v1 backup is refused on listing")
    func backupThrowsOnMalformedFile() {
        #expect(throws: WalletBackupDecodingError.self) {
            try format.backup(from: Data("not json at all".utf8), fileName: "Wallet.backup.json")
        }
    }

    // MARK: - Tampering

    @Test("A relabeled backup id fails authentication even with the correct password")
    func tamperedIdFailsAuthentication() throws {
        let fileData = try Self.makeFileData()
        let mutated = try Self.mutatingTopLevelField(
            fileData,
            key: "id",
            value: "ffffffff-ffff-ffff-ffff-ffffffffffff"
        )

        #expect {
            try format.payload(from: mutated, password: Self.password)
        } throws: { error in
            guard case WalletBackupCryptoError.invalidPassword = error else {
                return false
            }
            return true
        }
    }

    @Test("Unknown cipher label is refused before any key derivation")
    func unknownCipherLabelIsRefused() throws {
        let fileData = try Self.makeFileData()
        let mutated = try Self.mutatingCryptoField(fileData, key: "cipher", value: "aes-128-cbc")

        #expect {
            try format.payload(from: mutated, password: Self.password)
        } throws: { error in
            guard case WalletBackupDecodingError.unsupportedAlgorithm(let algorithm) = error else {
                return false
            }
            return algorithm == "aes-128-cbc"
        }
    }

    @Test("Unknown KDF label is refused before any key derivation")
    func unknownKDFLabelIsRefused() throws {
        let fileData = try Self.makeFileData()
        let mutated = try Self.mutatingCryptoField(fileData, key: "kdf", value: "scrypt")

        #expect {
            try format.payload(from: mutated, password: Self.password)
        } throws: { error in
            guard case WalletBackupDecodingError.unsupportedAlgorithm(let algorithm) = error else {
                return false
            }
            return algorithm == "scrypt"
        }
    }

    // MARK: - Password canonicalization

    @Test("Edge whitespace and Unicode form of the password do not lock the user out")
    func passwordIsCanonicalized() throws {
        let accentedPassword = "Pässwörd#1"
        let decomposedWithWhitespace = " \(accentedPassword.decomposedStringWithCanonicalMapping)\n"
        let precomposed = accentedPassword.precomposedStringWithCanonicalMapping

        let file = try Self.makeFile(password: decomposedWithWhitespace)
        let fileData = try WalletBackupJSONCodec.encode(file)

        let payload = try format.payload(from: fileData, password: precomposed)

        #expect(payload.mnemonicWords == Self.mnemonicWords)
    }
}

// MARK: - File fixtures

private extension WalletBackupFormatV1FileTests {
    static let mnemonicWords = [
        "abandon", "abandon", "abandon", "abandon", "abandon", "abandon",
        "abandon", "abandon", "abandon", "abandon", "abandon", "about",
    ]
    static let password = "Backup#Password1"

    static func makeFile(password: String = password) throws -> WalletBackupFormatV1.File {
        try WalletBackupFormatV1().makeFile(
            payload: CommonWalletBackupPayload(mnemonicWords: mnemonicWords, requiresPassphrase: false),
            walletName: "Wallet",
            walletId: "wallet-id",
            password: password
        )
    }

    static func makeFileData() throws -> Data {
        try WalletBackupJSONCodec.encode(makeFile())
    }

    /// Rewrites one top-level field of the file JSON, leaving the `crypto` section intact —
    /// how an attacker or a buggy tool would edit the plaintext part of the file.
    static func mutatingTopLevelField(_ fileData: Data, key: String, value: Any) throws -> Data {
        var object = try #require(JSONSerialization.jsonObject(with: fileData) as? [String: Any])
        object[key] = value
        return try JSONSerialization.data(withJSONObject: object)
    }

    static func mutatingCryptoField(_ fileData: Data, key: String, value: Any) throws -> Data {
        var object = try #require(JSONSerialization.jsonObject(with: fileData) as? [String: Any])
        var crypto = try #require(object["crypto"] as? [String: Any])
        crypto[key] = value
        object["crypto"] = crypto
        return try JSONSerialization.data(withJSONObject: object)
    }
}
