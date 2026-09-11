//
//  DPoPProofGenerator.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

private import Foundation
private import struct CryptoKit.SHA256
private import TangemFoundation

/// Builds RFC 9449 ``DPoPProof``, signed with the device's private key via ``DeviceKeyManager``.
public struct DPoPProofGenerator: Sendable {
    private let deviceKeyManager: DeviceKeyManager
    private let encoder: JSONEncoder

    init(deviceKeyManager: DeviceKeyManager) {
        self.deviceKeyManager = deviceKeyManager
        encoder = JSONEncoder()
    }

    /// Builds and signs a fresh DPoP proof for some HTTP request.
    ///
    /// - Parameters:
    ///   - htm: The request's HTTP method.
    ///   - htu: The request's URI, without query or fragment.
    ///   - accessToken: The access token this proof accompanies, if any.
    /// When present, its SHA-256 hash is embedded as the `ath` claim; when `nil`, `ath` is omitted entirely.
    /// - Returns: A ``DPoPProof`` ready to send as the `DPoP` request header.
    /// - Throws: ``DeviceKeyManagerError`` if the device key is unavailable or signing fails.
    public func generate(htm: String, htu: String, accessToken: String?) async throws(DeviceKeyManagerError) -> DPoPProof {
        let devicePublicKey = try await deviceKeyManager.publicKey

        let header = Header(jwk: JWK(devicePublicKey: devicePublicKey))
        let claims = Claims(htm: htm, htu: htu, accessToken: accessToken)

        let signingInput = "\(encode(header)).\(encode(claims))"
        let signingInputBytes = Data(signingInput.utf8)

        let signature = try await deviceKeyManager.sign(data: signingInputBytes)

        return DPoPProof(value: "\(signingInput).\(signature.rawRepresentation.base64URLEncodedString)")
    }
}

// MARK: - Encodable and DTOs

extension DPoPProofGenerator {
    private func encode(_ value: some Encodable) -> String {
        do {
            return try encoder.encode(value).base64URLEncodedString
        } catch {
            fatalError("DPoP proof DTOs structure corrupted: \(error). A developer mistake.")
        }
    }

    /// The DPoP proof's JOSE header, embedding the device's public key as a JWK.
    ///
    /// - SeeAlso: https://www.rfc-editor.org/rfc/rfc9449.html#name-dpop-proof-jwt-syntax
    private struct Header: Encodable {
        let typ = "dpop+jwt"
        let alg = "ES256"
        let jwk: JWK
    }

    /// The device's P-256 public key, expressed as an EC JWK.
    ///
    /// - SeeAlso: https://www.rfc-editor.org/rfc/rfc9449.html#name-dpop-proof-jwt-syntax
    private struct JWK: Encodable {
        let kty = "EC"
        let crv = "P-256"
        let x: String
        let y: String

        init(devicePublicKey: DevicePublicKey) {
            x = devicePublicKey.x.base64URLEncodedString
            y = devicePublicKey.y.base64URLEncodedString
        }
    }

    /// The DPoP proof's claims: its one-time identity, the request it's bound to, and optionally the access token it's tied to.
    ///
    /// - SeeAlso: https://www.rfc-editor.org/rfc/rfc9449.html#name-dpop-proof-jwt-syntax
    private struct Claims: Encodable {
        let jti = UUID().uuidString
        let htm: String
        let htu: String
        let iat = Int(Date().timeIntervalSince1970)
        let ath: String?

        init(htm: String, htu: String, accessToken: String?) {
            self.htm = htm
            self.htu = htu
            ath = accessToken.map { Data(SHA256.hash(data: Data($0.utf8))).base64URLEncodedString }
        }
    }
}
