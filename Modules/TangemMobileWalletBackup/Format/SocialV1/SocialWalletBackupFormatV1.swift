//
//  SocialWalletBackupFormatV1.swift
//  TangemMobileWalletBackup
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct SocialWalletBackupFormatV1: SocialWalletBackupFormat {
    private let cryptor = AESGCMWalletBackupCryptor()

    func makeFile(
        payload: any WalletBackupPayload,
        walletId: String,
        key: Data
    ) throws -> File {
        var plaintext = try WalletBackupPayloadDTO.encode(payload)
        defer { plaintext.secureErase() }

        let version = SocialWalletBackupFormatVersion.v1
        let additionalData = Self.additionalData(version: version, walletId: walletId)
        let sealedBox = try cryptor.encrypt(plaintext, key: key, additionalData: additionalData)
        let createdAt = WalletBackupDateFormatter.iso8601.string(from: Date())

        let crypto = File.Crypto(
            cipher: cryptor.algorithmName,
            cipherparams: File.CipherParams(nonce: sealedBox.nonce),
            ciphertext: sealedBox.ciphertext,
            tag: sealedBox.tag
        )

        return File(
            version: version,
            walletId: walletId,
            createdAt: createdAt,
            crypto: crypto
        )
    }

    func backup(from fileData: Data) throws -> MobileWalletSocialBackup {
        let file = try decodeFile(fileData)

        return MobileWalletSocialBackup(
            walletId: file.walletId,
            createdAt: WalletBackupDateFormatter.iso8601.date(from: file.createdAt),
            fileData: fileData
        )
    }

    func payload(from fileData: Data, key: Data) throws -> any WalletBackupPayload {
        let file = try decodeFile(fileData)

        guard file.crypto.cipher == cryptor.algorithmName else {
            throw WalletBackupDecodingError.unsupportedAlgorithm(file.crypto.cipher)
        }

        let sealedBox = WalletBackupSealedBox(
            nonce: file.crypto.cipherparams.nonce,
            ciphertext: file.crypto.ciphertext,
            tag: file.crypto.tag
        )

        let additionalData = Self.additionalData(version: file.version, walletId: file.walletId)

        var payloadData = try decrypt(sealedBox, key: key, additionalData: additionalData)
        defer { payloadData.secureErase() }

        return try WalletBackupPayloadDTO.decode(payloadData)
    }
}

// MARK: - Private implementation

private extension SocialWalletBackupFormatV1 {
    func decrypt(_ sealedBox: WalletBackupSealedBox, key: Data, additionalData: Data) throws(WalletBackupCryptoError) -> Data {
        do {
            return try cryptor.decrypt(sealedBox, key: key, additionalData: additionalData)
        } catch .invalidPassword {
            throw .invalidRecoveryKey
        }
    }

    func decodeFile(_ fileData: Data) throws -> File {
        do {
            return try WalletBackupJSONCodec.decode(File.self, from: fileData)
        } catch {
            throw WalletBackupDecodingError.decodingFailed(error)
        }
    }

    static func additionalData(version: SocialWalletBackupFormatVersion, walletId: String) -> Data {
        Data("\(version.rawValue).\(walletId)".utf8)
    }
}
