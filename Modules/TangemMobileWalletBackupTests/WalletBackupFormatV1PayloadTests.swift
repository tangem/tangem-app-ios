//
//  WalletBackupFormatV1PayloadTests.swift
//  TangemMobileWalletBackupTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemMobileWalletBackup

@Suite("WalletBackupFormatV1 payload passphrase")
struct WalletBackupFormatV1PayloadTests {
    private let format = WalletBackupFormatV1()

    @Test("Backup of a passphrase-protected wallet stores the requirement, not the passphrase")
    func passphraseRequiredRoundTrip() throws {
        let fileData = try Self.makeFileData(requiresPassphrase: true)

        let payload = try format.payload(from: fileData, password: Self.password)

        #expect(payload.mnemonicWords == Self.mnemonicWords)
        #expect(payload.requiresPassphrase)

        // Pin the wire format itself: no passphrase key at all, only the numeric flag.
        let payloadJSON = try Self.decryptPayloadJSON(fileData: fileData)
        #expect(payloadJSON["passphrase"] == nil)
        #expect(payloadJSON["passphraseRequired"] as? Int == 1)
    }

    @Test("Backup of a wallet without a passphrase requires nothing on restore")
    func noPassphraseRoundTrip() throws {
        let fileData = try Self.makeFileData(requiresPassphrase: false)

        let payload = try format.payload(from: fileData, password: Self.password)

        #expect(payload.mnemonicWords == Self.mnemonicWords)
        #expect(!payload.requiresPassphrase)

        let payloadJSON = try Self.decryptPayloadJSON(fileData: fileData)
        #expect(payloadJSON["passphrase"] == nil)
        #expect(payloadJSON["passphraseRequired"] as? Int == 0)
    }

    @Test("Legacy file with an embedded passphrase is rejected")
    func legacyFileIsRejected() throws {
        let fileData = try Self.makeLegacyFileData()

        #expect {
            try format.payload(from: fileData, password: Self.password)
        } throws: { error in
            guard case WalletBackupDecodingError.payloadDecodingFailed = error else {
                return false
            }
            return true
        }
    }
}

// MARK: - File fixtures

private extension WalletBackupFormatV1PayloadTests {
    static let mnemonicWords = [
        "abandon", "abandon", "abandon", "abandon", "abandon", "abandon",
        "abandon", "abandon", "abandon", "abandon", "abandon", "about",
    ]
    static let password = "Backup#Password1"

    /// A file written by the current code.
    static func makeFileData(requiresPassphrase: Bool) throws -> Data {
        let file = try WalletBackupFormatV1().makeFile(
            payload: CommonWalletBackupPayload(mnemonicWords: mnemonicWords, requiresPassphrase: requiresPassphrase),
            walletName: "Wallet",
            walletId: "wallet-id",
            password: password
        )
        return try WalletBackupJSONCodec.encode(file)
    }

    /// Decrypts the payload of a file written by the current code and returns
    /// its raw JSON object, so tests can pin the exact wire format.
    static func decryptPayloadJSON(fileData: Data) throws -> [String: Any] {
        let file = try WalletBackupJSONCodec.decode(WalletBackupFormatV1.File.self, from: fileData)

        let kdfParams = try Argon2idKDFParameters(
            version: file.crypto.kdfparams.version,
            memory: file.crypto.kdfparams.memory,
            iterations: file.crypto.kdfparams.iterations,
            parallelism: file.crypto.kdfparams.parallelism,
            dklen: file.crypto.kdfparams.dklen,
            salt: file.crypto.kdfparams.salt
        )
        let key = try Argon2idWalletBackupKeyDerivator().deriveKey(password: password, params: kdfParams)

        let sealedBox = WalletBackupSealedBox(
            nonce: file.crypto.cipherparams.nonce,
            ciphertext: file.crypto.ciphertext,
            tag: file.crypto.tag
        )
        let additionalData = Data("\(file.version.rawValue).\(file.id)".utf8)
        let plaintext = try AESGCMWalletBackupCryptor().decrypt(sealedBox, key: key, additionalData: additionalData)

        return try JSONSerialization.jsonObject(with: plaintext) as? [String: Any] ?? [:]
    }

    /// A file as early builds wrote it: the payload embeds the passphrase itself
    /// and has no `passphraseRequired` field. That schema is unsupported — such
    /// files must be rejected, not misread as passphrase-free backups.
    static func makeLegacyFileData() throws -> Data {
        let keyDerivator = Argon2idWalletBackupKeyDerivator()
        let cryptor = AESGCMWalletBackupCryptor()

        // Deliberately weak parameters: the fixture only needs to decrypt, not to resist
        // brute force, and the default preset would slow every test run by seconds.
        let kdfParams = try Argon2idKDFParameters(
            version: Argon2idKDFParameters.Constants.argon2Version13,
            memory: 8,
            iterations: 1,
            parallelism: Argon2idKDFParameters.Constants.supportedParallelism,
            dklen: 32,
            salt: Data(repeating: 0xAB, count: Argon2idKDFParameters.Constants.saltLength)
        )
        let key = try keyDerivator.deriveKey(password: password, params: kdfParams)

        let legacyPayload: [String: String] = [
            "mnemonic": mnemonicWords.joined(separator: " "),
            "passphrase": "legacy passphrase",
        ]
        let plaintext = try JSONSerialization.data(withJSONObject: legacyPayload)

        let version = WalletBackupFormatVersion.v1
        let backupID = "00000000-0000-0000-0000-000000000000"
        let additionalData = Data("\(version.rawValue).\(backupID)".utf8)
        let sealedBox = try cryptor.encrypt(plaintext, key: key, additionalData: additionalData)

        let file = WalletBackupFormatV1.File(
            version: version,
            id: backupID,
            name: "Wallet",
            walletId: "wallet-id",
            createdAt: "2026-08-07T00:00:00Z",
            crypto: WalletBackupFormatV1.File.Crypto(
                cipher: cryptor.algorithmName,
                cipherparams: WalletBackupFormatV1.File.CipherParams(nonce: sealedBox.nonce),
                ciphertext: sealedBox.ciphertext,
                tag: sealedBox.tag,
                kdf: keyDerivator.algorithmName,
                kdfparams: WalletBackupFormatV1.File.KDFParams(
                    version: kdfParams.version,
                    memory: kdfParams.memory,
                    iterations: kdfParams.iterations,
                    parallelism: kdfParams.parallelism,
                    dklen: kdfParams.dklen,
                    salt: kdfParams.salt
                )
            )
        )
        return try WalletBackupJSONCodec.encode(file)
    }
}
