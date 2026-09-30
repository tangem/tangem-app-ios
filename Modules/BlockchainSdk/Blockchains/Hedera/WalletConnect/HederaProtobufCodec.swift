//
//  HederaProtobufCodec.swift
//  BlockchainSdk
//
//  Created by Dean Rie
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Minimal hand-rolled protobuf for the three HAPI messages HIP-820 exchanges outside the Hiero SDK's typed API.
///
/// ```
/// SignatureMap      { repeated SignaturePair sigPair = 1; }
/// SignaturePair     { bytes pubKeyPrefix = 1; oneof { bytes ed25519 = 3; bytes ECDSA_secp256k1 = 6; } }
/// SignedTransaction { bytes bodyBytes = 1; SignatureMap sigMap = 2; }
/// Transaction       { bytes signedTransactionBytes = 5; }
/// ```
/// `HieroProtobufs` is not a product of the SDK package, and these are the only shapes needed.
public enum HederaProtobufCodec {
    public enum SignatureKind: Equatable {
        case ed25519
        case ecdsaSecp256k1

        fileprivate var fieldNumber: UInt32 {
            switch self {
            case .ed25519: 3
            case .ecdsaSecp256k1: 6
            }
        }
    }

    /// Serialised `SignatureMap` with one `SignaturePair` whose prefix is the full public key.
    public static func signatureMap(publicKey: Data, signature: Data, kind: SignatureKind) -> Data {
        let pair = lengthDelimited(field: 1, publicKey) + lengthDelimited(field: kind.fieldNumber, signature)
        return lengthDelimited(field: 1, pair)
    }

    /// Wraps a bare `TransactionBody` into an unsigned `Transaction` so `Hiero.Transaction.fromBytes` can decode it.
    public static func transaction(wrappingBody bodyBytes: Data) -> Data {
        lengthDelimited(field: 5, lengthDelimited(field: 1, bodyBytes))
    }

    /// `"\u{19}Hedera Signed Message:\n" ‖ decimal(len(message)) ‖ message` — the bytes `hedera_signMessage` signs.
    ///
    /// `len` follows the reference implementation (`@hashgraph/hedera-wallet-connect`, `prefixMessageToSign`):
    /// JavaScript `message.length`, i.e. the number of UTF-16 code units, not UTF-8 bytes. dApps verify with the
    /// same helper, so the wallet must count the same way.
    public static func signedMessageBytes(_ message: String) -> Data {
        Data("\u{19}Hedera Signed Message:\n".utf8) + Data(String(message.utf16.count).utf8) + Data(message.utf8)
    }

    private static func lengthDelimited(field: UInt32, _ payload: Data) -> Data {
        varint(UInt64(field << 3 | 2)) + varint(UInt64(payload.count)) + payload
    }

    private static func varint(_ value: UInt64) -> Data {
        var value = value
        var out = Data()
        repeat {
            let byte = UInt8(value & 0x7F)
            value >>= 7
            out.append(value == 0 ? byte : byte | 0x80)
        } while value != 0
        return out
    }
}
