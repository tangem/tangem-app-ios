//
//  TonConnectProofMessage.swift
//  TangemModules
//
//  Created by Dean Rie
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import CryptoKit
import Foundation
import TonSwift

/// Byte layout and digest of the `ton_proof` connect item (`spec/connect.md` § Address proof signature).
///
/// ```
/// message   = "ton-proof-item-v2/" ++ workchain:int32be ++ hash:32 ++ len(domain):uint32le ++ domain ++ timestamp:uint64le ++ payload
/// signature = Ed25519Sign(sha256(0xffff ++ "ton-connect" ++ sha256(message)))
/// ```
///
/// Note the mixed endianness — it is part of the wire format and differs from `signData`.
public enum TonConnectProofMessage {
    static let itemPrefix = Data("ton-proof-item-v2/".utf8)
    static let signaturePrefix = Data([0xFF, 0xFF]) + Data("ton-connect".utf8)

    /// The unhashed proof message.
    public static func message(address: Address, appDomain: String, timestamp: UInt64, payload: String) -> Data {
        var message = itemPrefix
        message.append(address.tonConnectProofEncoding)

        let domain = Data(appDomain.utf8)
        message.append(UInt32(domain.count).tonConnectLittleEndianBytes)
        message.append(domain)

        message.append(timestamp.tonConnectLittleEndianBytes)
        message.append(Data(payload.utf8))
        return message
    }

    /// The 32-byte digest handed to the Ed25519 signer.
    public static func digest(address: Address, appDomain: String, timestamp: UInt64, payload: String) -> Data {
        let inner = SHA256.hash(data: message(address: address, appDomain: appDomain, timestamp: timestamp, payload: payload))
        return Data(SHA256.hash(data: signaturePrefix + Data(inner)))
    }

    /// Signs the proof for `address` and packages it as the `ton_proof` reply item.
    public static func makeProof(
        address: Address,
        appDomain: String,
        payload: String,
        timestamp: UInt64,
        signer: any TonConnectSigner
    ) async throws -> TonConnectProof {
        let digest = digest(address: address, appDomain: appDomain, timestamp: timestamp, payload: payload)
        let signature = try await signer.sign(digest: digest)

        guard signature.count == 64 else {
            throw TonConnectError.internalFailure("signer returned \(signature.count) bytes, expected 64")
        }

        return TonConnectProof(timestamp: timestamp, domain: appDomain, signature: signature, payload: payload)
    }
}

extension Address {
    /// `workchain` as a 32-bit signed big-endian integer followed by the 256-bit account hash.
    var tonConnectProofEncoding: Data {
        Int32(workchain).tonConnectBigEndianBytes + hash
    }
}

extension FixedWidthInteger {
    var tonConnectBigEndianBytes: Data {
        withUnsafeBytes(of: bigEndian) { Data($0) }
    }

    var tonConnectLittleEndianBytes: Data {
        withUnsafeBytes(of: littleEndian) { Data($0) }
    }
}
