//
//  CloreMigrationMessageSigner.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk
import struct Commons.AnyCodable
import enum JSONRPC.RPCResult

struct CloreMigrationMessageSigner {
    private let message: String
    private let signer: WalletConnectSigner
    private let walletModel: any WalletModel

    private var dataToSign: Data {
        let hexData = Data(hex: message)
        // If received message is not a hex string, then convert it to bytes
        if hexData.isEmpty, !message.hasHexPrefix() {
            return message.data(using: .utf8) ?? Data()
        } else {
            return hexData
        }
    }

    init(
        message: String,
        blockchainId: String,
        signer: WalletConnectSigner,
        walletModelProvider: WalletConnectWalletModelProvider
    ) throws {
        guard let walletModel = walletModelProvider.getModel(with: blockchainId) else {
            throw CloreMigrationSigningError.failedToGetWalletModel(blockchainId: blockchainId)
        }
        self.walletModel = walletModel

        self.message = message
        self.signer = signer
    }

    init(
        message: String,
        blockchainId: String,
        signer: WalletConnectSigner,
        wcAccountsWalletModelProvider: WalletConnectAccountsWalletModelProvider,
        accountId: String
    ) throws {
        guard let walletModel = wcAccountsWalletModelProvider.getModel(with: blockchainId, accountId: accountId) else {
            throw CloreMigrationSigningError.failedToGetWalletModel(blockchainId: blockchainId)
        }

        self.walletModel = walletModel
        self.message = message
        self.signer = signer
    }

    private func createMessageHash(message: Data) -> Data {
        var payload = Data()
        payload.append(Constants.cloreMessageMagic.data(using: .utf8) ?? Data())
        payload.append(varInt(of: message.count))
        payload.append(message)
        return payload.sha256().sha256()
    }

    private func createRecoverableSignature(
        signature: Data,
        publicKey: Data,
        messageHash: Data
    ) throws -> Data {
        let (r, s, recoveryId) = try extractSignatureComponents(
            signature: signature,
            publicKey: publicKey,
            messageHash: messageHash
        )

        guard recoveryId <= Constants.maxRecoveryId else {
            throw CloreMigrationSigningError.invalidSignature
        }

        let headerBase = publicKey.count == Constants.compressedPublicKeyLength
            ? Constants.compressedHeaderBase
            : Constants.uncompressedHeaderBase
        let header = headerBase + recoveryId

        return Data([header]) + r + s
    }

    private func extractSignatureComponents(
        signature: Data,
        publicKey: Data,
        messageHash: Data
    ) throws -> (r: Data, s: Data, recoveryId: UInt8) {
        if signature.count == Constants.recoverableSignatureLength {
            let r = signature.prefix(Constants.componentLength)
            let s = signature.dropFirst(Constants.componentLength).prefix(Constants.componentLength)
            let v = signature.suffix(Constants.recoveryIdLength).first ?? 0
            return (Data(r), Data(s), normalizeRecoveryId(v))
        }

        let unmarshalledSignature = try Secp256k1Signature(with: signature)
            .unmarshal(with: publicKey, hash: messageHash)

        guard let v = unmarshalledSignature.v.first else {
            throw CloreMigrationSigningError.invalidSignature
        }

        return (
            r: unmarshalledSignature.r,
            s: unmarshalledSignature.s,
            recoveryId: normalizeRecoveryId(v)
        )
    }

    private func normalizeRecoveryId(_ value: UInt8) -> UInt8 {
        if value >= Constants.recoveryIdOffset {
            return value - Constants.recoveryIdOffset
        }

        return value
    }

    /// Clore compactSize (varint) encoding for the length
    private func varInt(of length: Int) -> Data {
        if length < 0xFD {
            return Data([UInt8(length)])
        } else if length <= 0xFFFF {
            var value = UInt16(length).littleEndian
            return Data([0xFD]) + withUnsafeBytes(of: &value) { Data($0) }
        } else if length <= 0xFFFF_FFFF {
            var value = UInt32(length).littleEndian
            return Data([0xFE]) + withUnsafeBytes(of: &value) { Data($0) }
        } else {
            var value = UInt64(length).littleEndian
            return Data([0xFF]) + withUnsafeBytes(of: &value) { Data($0) }
        }
    }
}

extension CloreMigrationMessageSigner {
    var requestData: Data {
        Data(hex: message)
    }

    func handle() async throws -> String {
        let messageHash = createMessageHash(message: dataToSign)

        do {
            let signedMessage = try await signer.sign(data: messageHash, using: walletModel)
            let recoverableSignature = try createRecoverableSignature(
                signature: signedMessage,
                publicKey: walletModel.publicKey.blockchainKey,
                messageHash: messageHash
            )
            return recoverableSignature.base64EncodedString()
        } catch {
            AppLogger.error("Failed to sign message", error: error)
            throw error
        }
    }
}

private extension CloreMigrationMessageSigner {
    enum Constants {
        static let cloreMessageMagic = "\u{16}Clore Signed Message:\n"
        static let componentLength = 32
        static let recoverableSignatureLength = 65
        static let recoveryIdLength = 1
        static let recoveryIdOffset: UInt8 = 27
        static let maxRecoveryId: UInt8 = 3
        static let compressedHeaderBase: UInt8 = 31
        static let uncompressedHeaderBase: UInt8 = 27
        static let compressedPublicKeyLength = 33
    }
}
