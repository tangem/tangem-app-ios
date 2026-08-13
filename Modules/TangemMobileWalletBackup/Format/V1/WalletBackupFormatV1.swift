//
//  WalletBackupFormatV1.swift
//  TangemMobileWalletBackup
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct WalletBackupFormatV1: WalletBackupFormat {
    // The crypto suite is part of the format version's definition — v1 files are
    // written and read with exactly these primitives, so they are not injectable.
    private let keyDerivator = Argon2idWalletBackupKeyDerivator()
    private let cryptor = AESGCMWalletBackupCryptor()

    func makeFile(
        payload: any WalletBackupPayload,
        walletName: String,
        walletId: String,
        password: String
    ) throws -> File {
        let kdfParams = try keyDerivator.makeDefaultParams()

        var key = try keyDerivator.deriveKey(password: Self.canonicalPassword(password), params: kdfParams)
        defer { secureErase(data: &key) }

        var plaintext = try encodePayload(payload)
        defer { secureErase(data: &plaintext) }

        let version = WalletBackupFormatVersion.v1
        let backupID = UUID().uuidString.lowercased()

        // AAD binds the ciphertext to this exact backup: a `crypto` section transplanted
        // from another file fails authentication even with the correct password. Including
        // the version also prevents relabeling a file to route it through legacy parsing.
        let additionalData = Self.additionalData(version: version, backupID: backupID)
        let sealedBox = try cryptor.encrypt(plaintext, key: key, additionalData: additionalData)
        let createdAt = Self.iso8601Formatter.string(from: Date())

        return File(
            version: version,
            id: backupID,
            name: walletName,
            walletId: walletId,
            createdAt: createdAt,
            crypto: File.Crypto(
                cipher: cryptor.algorithmName,
                cipherparams: File.CipherParams(nonce: sealedBox.nonce),
                ciphertext: sealedBox.ciphertext,
                tag: sealedBox.tag,
                kdf: keyDerivator.algorithmName,
                kdfparams: File.KDFParams(kdfParams)
            )
        )
    }

    func metadata(from fileData: Data, fileName: String) throws -> WalletBackupMetadata {
        let file = try decodeFile(fileData)

        return WalletBackupMetadata(
            fileName: fileName,
            walletName: file.name,
            walletId: file.walletId,
            createdAt: Self.iso8601Formatter.date(from: file.createdAt)
        )
    }

    func payload(from fileData: Data, password: String) throws -> any WalletBackupPayload {
        let file = try decodeFile(fileData)

        // The algorithm labels stored in the file are redundant by design — v1's crypto
        // suite is fixed — so a mismatch means the file wasn't produced by a compliant
        // v1 writer (corruption, tampering, a buggy writer). Refuse it early with a
        // precise error instead of burning ~1 s of KDF and failing GCM authentication
        // with a misleading `invalidPassword`.
        guard file.crypto.cipher == cryptor.algorithmName else {
            throw WalletBackupDecodingError.unsupportedAlgorithm(file.crypto.cipher)
        }
        guard file.crypto.kdf == keyDerivator.algorithmName else {
            throw WalletBackupDecodingError.unsupportedAlgorithm(file.crypto.kdf)
        }

        let sealedBox = WalletBackupSealedBox(
            nonce: file.crypto.cipherparams.nonce,
            ciphertext: file.crypto.ciphertext,
            tag: file.crypto.tag
        )

        // KDF params always come from the file, never from the current default preset —
        // the preset may get stronger over time without breaking old files.
        let kdfParams = try Argon2idKDFParameters(
            version: file.crypto.kdfparams.version,
            memory: file.crypto.kdfparams.memory,
            iterations: file.crypto.kdfparams.iterations,
            parallelism: file.crypto.kdfparams.parallelism,
            dklen: file.crypto.kdfparams.dklen,
            salt: file.crypto.kdfparams.salt
        )

        var key = try keyDerivator.deriveKey(password: Self.canonicalPassword(password), params: kdfParams)
        defer { secureErase(data: &key) }

        let additionalData = Self.additionalData(version: file.version, backupID: file.id)

        var payloadData = try cryptor.decrypt(sealedBox, key: key, additionalData: additionalData)
        defer { secureErase(data: &payloadData) }

        return try decodePayload(payloadData)
    }
}

// MARK: - Mapping

private extension WalletBackupFormatV1.File.KDFParams {
    /// Maps the crypto-layer parameters into the v1 serialization shape.
    init(_ parameters: Argon2idKDFParameters) {
        self.init(
            version: parameters.version,
            memory: parameters.memory,
            iterations: parameters.iterations,
            parallelism: parameters.parallelism,
            dklen: parameters.dklen,
            salt: parameters.salt
        )
    }
}

// MARK: - Payload serialization

private extension WalletBackupFormatV1 {
    /// Canonical plaintext schema of v1 files. Backups created today are restored by
    /// future app versions — this schema must keep decoding forever.
    struct PayloadDTO: Codable {
        let mnemonic: String
        let passphrase: String
    }

    func encodePayload(_ payload: any WalletBackupPayload) throws -> Data {
        let dto = PayloadDTO(
            mnemonic: payload.mnemonicWords.joined(separator: " "),
            passphrase: payload.passphrase
        )
        do {
            return try WalletBackupJSONCodec.encode(dto)
        } catch {
            // The underlying error is dropped on purpose — it can embed the plaintext.
            throw WalletBackupEncodingError.payloadEncodingFailed
        }
    }

    func decodePayload(_ payloadData: Data) throws -> CommonWalletBackupPayload {
        do {
            let dto = try WalletBackupJSONCodec.decode(PayloadDTO.self, from: payloadData)
            return CommonWalletBackupPayload(
                mnemonicWords: dto.mnemonic.split(separator: " ").map(String.init),
                passphrase: dto.passphrase
            )
        } catch {
            // The underlying error is dropped on purpose — it can embed the plaintext.
            throw WalletBackupDecodingError.payloadDecodingFailed
        }
    }
}

// MARK: - Private implementation

private extension WalletBackupFormatV1 {
    func decodeFile(_ fileData: Data) throws -> File {
        do {
            return try WalletBackupJSONCodec.decode(File.self, from: fileData)
        } catch {
            throw WalletBackupDecodingError.decodingFailed(error)
        }
    }

    /// Password canonicalization is part of the v1 format definition, like the crypto
    /// suite: a different canonical form would derive a different key and lock users out
    /// of existing backups, so these two rules must never change for v1 files.
    ///
    /// Trimming (mirrored by the password validator) protects against accidental edge
    /// whitespace — e.g. the keyboard auto-space after an autocomplete. NFC normalization
    /// protects against the same visible character (e.g. an accented letter) arriving as
    /// different UTF-8 byte sequences depending on the platform/keyboard.
    static func canonicalPassword(_ password: String) -> String {
        password
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .precomposedStringWithCanonicalMapping
    }

    static func additionalData(version: WalletBackupFormatVersion, backupID: String) -> Data {
        Data("\(version.rawValue).\(backupID)".utf8)
    }

    static let iso8601Formatter = ISO8601DateFormatter()
}
