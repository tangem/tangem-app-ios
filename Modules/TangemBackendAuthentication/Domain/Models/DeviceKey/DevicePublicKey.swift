//
//  DevicePublicKey.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public import struct Foundation.Data

/// P-256 (secp256r1) public key used for device registration, authentication and session generation.
///
/// The device generates a key pair once, on first launch.
/// The private key never leaves the Secure Enclave.
/// The public key is sent to the backend in one of two encodings, depending on which request it's part of.
public struct DevicePublicKey: Equatable, Sendable {
    /// The public key as an X.509 SubjectPublicKeyInfo (SPKI) structure, DER (Distinguished Encoding Rules) encoded.
    ///
    /// Sent as the `devicePublicKey` field of either request payload:
    ///   | request             | endpoint                                      |
    ///   | ---                 | ---                                           |
    ///   | device registration | `POST /mobile/register`                       |
    ///   | authentication      | `POST /mobile/authenticate`                   |
    ///   | nonce generation    | `POST /mobile/nonce/{device\|auth\|wallet}`   |
    public let derRepresentation: Data

    /// The public key as a raw, uncompressed elliptic curve point: `0x04 ‖ X ‖ Y`.
    ///
    /// Used to build the JWK (JSON Web Key) embedded in every DPoP (Demonstrating Proof-of-Possession)
    /// proof attached to session-authenticated requests.
    ///
    ///  - Invariant: Exactly 65 bytes long: 1 byte prefix (0x04) + 32 bytes X coordinate + 32 bytes Y coordinate.
    public let rawPoint: Data

    /// ``rawPoint``'s X coordinate: the 32 bytes immediately following the uncompressed-point prefix.
    var x: Data {
        rawPoint.dropFirst().prefix(Constants.coordinateByteCount)
    }

    /// ``rawPoint``'s Y coordinate: its last 32 bytes.
    var y: Data {
        rawPoint.suffix(Constants.coordinateByteCount)
    }

    init(derRepresentation: Data, rawPoint: Data) throws(RawPointFormatError) {
        guard rawPoint.count == Constants.rawPointByteCount else {
            throw RawPointFormatError.invalidLength(actual: rawPoint.count)
        }

        guard rawPoint.first == Constants.rawPointUncompressedPrefix else {
            throw RawPointFormatError.invalidPrefix(actual: rawPoint.first ?? 0)
        }

        self.derRepresentation = derRepresentation
        self.rawPoint = rawPoint
    }
}

extension DevicePublicKey {
    private enum Constants {
        static let rawPointByteCount = 65
        static let rawPointUncompressedPrefix: UInt8 = 0x04
        static let coordinateByteCount = 32
    }

    /// The specific way a raw elliptic curve point failed to match ``DevicePublicKey/rawPoint``'s expected format.
    public enum RawPointFormatError: Error, Equatable {
        /// The point isn't exactly 65 bytes (1-byte prefix + 32-byte X + 32-byte Y).
        case invalidLength(actual: Int)

        /// The point's first byte isn't `0x04` — i.e. it isn't an uncompressed point.
        case invalidPrefix(actual: UInt8)
    }
}
