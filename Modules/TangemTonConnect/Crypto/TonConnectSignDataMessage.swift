//
//  TonConnectSignDataMessage.swift
//  TangemModules
//
//  Created by Dean Rie
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import CryptoKit
import Foundation
import TonSwift

/// Digests for the `signData` method (`spec/rpc.md` § signData).
///
/// `text` / `binary`:
/// ```
/// message = 0xffff ++ "ton-connect/sign-data/" ++ workchain:int32be ++ hash:32
///           ++ len(domain):uint32be ++ domain ++ timestamp:uint64be
///           ++ ("txt" | "bin") ++ len(data):uint32be ++ data
/// digest  = sha256(message)
/// ```
/// All multi-byte integers are big-endian here (unlike `ton_proof`); this matches the reference verifier
/// published with the protocol.
///
/// `cell`:
/// ```
/// message#75569022 schema_hash:uint32 timestamp:uint64 user_address:MsgAddress
///                  app_domain:^SnakeData payload:^Cell
/// digest = message.hash()
/// ```
/// where `app_domain` is the TEP-81 DNS wire form of the domain (`io\0github\0ton-connect\0`).
public enum TonConnectSignDataMessage {
    public static let cellMagic: UInt32 = 0x7556_9022

    static let flatPrefix = Data([0xFF, 0xFF]) + Data("ton-connect/sign-data/".utf8)
    static let textPayloadPrefix = Data("txt".utf8)
    static let binaryPayloadPrefix = Data("bin".utf8)

    /// The unhashed message for `text` and `binary` payloads.
    public static func flatMessage(address: Address, appDomain: String, timestamp: UInt64, content: TonConnectSignDataPayload.Content) throws -> Data {
        let payloadPrefix: Data
        let payloadData: Data

        switch content {
        case .text(let text):
            payloadPrefix = textPayloadPrefix
            payloadData = Data(text.utf8)
        case .binary(let bytes):
            payloadPrefix = binaryPayloadPrefix
            payloadData = bytes
        case .cell:
            throw TonConnectError.badRequest("cell payloads are hashed as cells, not as flat messages")
        }

        var message = flatPrefix
        message.append(address.tonConnectProofEncoding)

        let domain = Data(appDomain.utf8)
        message.append(UInt32(domain.count).tonConnectBigEndianBytes)
        message.append(domain)

        message.append(timestamp.tonConnectBigEndianBytes)

        message.append(payloadPrefix)
        message.append(UInt32(payloadData.count).tonConnectBigEndianBytes)
        message.append(payloadData)
        return message
    }

    /// Builds the cell that is hashed for a `cell` payload.
    public static func cellMessage(address: Address, appDomain: String, timestamp: UInt64, schema: String, payload: Cell) throws -> Cell {
        let domainCell = try Builder().writeSnakeData(dnsWireFormat(of: appDomain)).endCell()

        return try Builder()
            .store(uint: cellMagic, bits: 32)
            .store(uint: CRC32.checksum(Data(schema.utf8)), bits: 32)
            .store(uint: timestamp, bits: 64)
            .store(address)
            .store(ref: domainCell)
            .store(ref: payload)
            .endCell()
    }

    /// The 32-byte digest handed to the Ed25519 signer, for any payload variant.
    public static func digest(address: Address, appDomain: String, timestamp: UInt64, payload: TonConnectSignDataPayload) throws -> Data {
        switch payload.content {
        case .text, .binary:
            let message = try flatMessage(address: address, appDomain: appDomain, timestamp: timestamp, content: payload.content)
            return Data(SHA256.hash(data: message))
        case .cell(let schema, let cellBoc):
            let cell = try TonConnectBoc.singleRootCell(base64: cellBoc, field: "cell")
            return try cellMessage(address: address, appDomain: appDomain, timestamp: timestamp, schema: schema, payload: cell).hash()
        }
    }

    /// Signs `payload` and packages the result for the `signData` response.
    public static func sign(
        payload: TonConnectSignDataPayload,
        address: Address,
        appDomain: String,
        timestamp: UInt64,
        signer: any TonConnectSigner
    ) async throws -> TonConnectSignDataResult {
        let digest = try digest(address: address, appDomain: appDomain, timestamp: timestamp, payload: payload)
        let signature = try await signer.sign(digest: digest)

        guard signature.count == 64 else {
            throw TonConnectError.internalFailure("signer returned \(signature.count) bytes, expected 64")
        }

        return TonConnectSignDataResult(
            signature: signature,
            address: address.toRaw(),
            timestamp: timestamp,
            domain: appDomain,
            payload: payload
        )
    }

    /// TEP-81 DNS wire format: labels in reverse order, each terminated by `\0`.
    static func dnsWireFormat(of domain: String) -> Data {
        var result = Data()
        for label in domain.split(separator: ".").reversed() {
            result.append(Data(label.utf8))
            result.append(0)
        }
        return result
    }
}

/// CRC-32 (IEEE 802.3, the `zlib`/`crc-32` npm variant) used for the schema hash of `cell` payloads.
enum CRC32 {
    private static let table: [UInt32] = (0 ..< 256).map { index -> UInt32 in
        var value = UInt32(index)
        for _ in 0 ..< 8 {
            value = (value & 1) == 1 ? (0xEDB8_8320 ^ (value >> 1)) : (value >> 1)
        }
        return value
    }

    static func checksum(_ data: Data) -> UInt32 {
        var crc: UInt32 = 0xFFFF_FFFF
        for byte in data {
            crc = table[Int((crc ^ UInt32(byte)) & 0xFF)] ^ (crc >> 8)
        }
        return crc ^ 0xFFFF_FFFF
    }
}
