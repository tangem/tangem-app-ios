//
//  DeviceSignature.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public import struct Foundation.Data

/// A signature produced by the device's private key,
/// used for device registration, authentication, and session-authenticated requests.
///
/// The device signs whatever data the caller provides:
/// - registration payload
/// - authentication payload
/// - DPoP (Demonstrating Proof-of-Possession) proof
///
/// The resulting signature is provided in one of two encodings, depending on which request it's part of.
/// - SeeAlso: ``DevicePublicKey`` for how the underlying key is generated and protected.
public struct DeviceSignature: Equatable, Sendable {
    /// The signature as ASN.1 (Abstract Syntax Notation One) DER (Distinguished Encoding Rules)
    /// encoded bytes: a `SEQUENCE` of two `INTEGER`s, `r` and `s`.
    ///
    /// Sent as the `signature` field of either request payload:
    ///   | request             | endpoint                          |
    ///   | ---                 | ---                               |
    ///   | device registration | `POST /mobile/register`           |
    ///   | authentication      | `POST /mobile/authenticate`       |
    public let derRepresentation: Data

    /// The signature as raw `r ‖ s` bytes, no ASN.1 wrapping.
    ///
    /// Signs the DPoP (Demonstrating Proof-of-Possession) proof's header and claims,
    /// attached to every session-authenticated request:
    ///
    ///   | request             | endpoint                          |
    ///   | ---                 | ---                               |
    ///   | token refresh       | `POST /mobile/token/refresh`      |
    ///   | wallet registration | `POST /mobile/wallet/register`    |
    ///
    /// - Invariant: Exactly 64 bytes long: 32 bytes for `r` + 32 bytes for `s`.
    /// - SeeAlso: ``DPoPProof``
    public let rawRepresentation: Data

    init(derRepresentation: Data, rawRepresentation: Data) throws(RawRepresentationFormatError) {
        guard rawRepresentation.count == Self.rawRepresentationByteCount else {
            throw RawRepresentationFormatError.invalidLength(actual: rawRepresentation.count)
        }

        self.derRepresentation = derRepresentation
        self.rawRepresentation = rawRepresentation
    }
}

extension DeviceSignature {
    private static let rawRepresentationByteCount = 64

    enum RawRepresentationFormatError: Error, Equatable {
        case invalidLength(actual: Int)
    }
}
