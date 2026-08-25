//
//  DPoPProofGeneratorTests.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import CryptoKit
import Foundation
import Testing
import TangemFoundation
@testable import TangemBackendAuthentication

@Suite(.tags(.backendAuthentication))
struct DPoPProofGeneratorTests {
    @Test
    func generateProducesThreeDotSeparatedSegments() async throws {
        let (sut, _) = makeSUT()

        let proof = try await sut.generate(htm: "POST", htu: Self.anyHTU, accessToken: nil)

        let segments = proof.value.split(separator: ".", omittingEmptySubsequences: false)
        #expect(segments.count == 3)
    }

    @Test
    func generateHeaderContainsFixedFieldsAndDevicePublicKeyCoordinates() async throws {
        let (sut, deviceKeyManager) = makeSUT()

        let proof = try await sut.generate(htm: "POST", htu: Self.anyHTU, accessToken: nil)
        let devicePublicKey = try await deviceKeyManager.publicKey
        let header = try Self.decodeHeader(from: proof)

        #expect(header.typ == "dpop+jwt")
        #expect(header.alg == "ES256")
        #expect(header.jwk.kty == "EC")
        #expect(header.jwk.crv == "P-256")

        let decodedX = try #require(header.jwk.x.base64URLDecodedData())
        let decodedY = try #require(header.jwk.y.base64URLDecodedData())

        #expect(decodedX == devicePublicKey.x)
        #expect(decodedY == devicePublicKey.y)
    }

    @Test
    func generateClaimsMatchTheGivenHTMAndHTU() async throws {
        let (sut, _) = makeSUT()

        let proof = try await sut.generate(htm: "POST", htu: Self.anyHTU, accessToken: nil)
        let claims = try Self.decodeClaims(from: proof)

        #expect(claims.htm == "POST")
        #expect(claims.htu == Self.anyHTU)
    }

    @Test
    func generateProducesUniqueJTIAndAPlausibleIAT() async throws {
        let (sut, _) = makeSUT()

        let beforeGenerate = Int(Date().timeIntervalSince1970)
        let firstProof = try await sut.generate(htm: "POST", htu: Self.anyHTU, accessToken: nil)
        let afterGenerate = Int(Date().timeIntervalSince1970)

        let secondProof = try await sut.generate(htm: "POST", htu: Self.anyHTU, accessToken: nil)

        let firstClaims = try Self.decodeClaims(from: firstProof)
        let secondClaims = try Self.decodeClaims(from: secondProof)

        #expect(UUID(uuidString: firstClaims.jti) != nil)
        #expect(UUID(uuidString: secondClaims.jti) != nil)
        #expect(firstClaims.jti != secondClaims.jti)

        #expect((beforeGenerate ... afterGenerate).contains(firstClaims.iat))
    }

    @Test
    func generateIncludesATHWhenAccessTokenIsProvided() async throws {
        let (sut, _) = makeSUT()
        let accessToken = "sample-access-token"

        let proof = try await sut.generate(htm: "POST", htu: Self.anyHTU, accessToken: accessToken)
        let claims = try Self.decodeClaims(from: proof)

        let ath = try #require(claims.ath)
        let decodedATH = try #require(ath.base64URLDecodedData())
        let expectedATHBytes = Data(SHA256.hash(data: Data(accessToken.utf8)))

        #expect(decodedATH == expectedATHBytes)
    }

    @Test
    func generateOmitsATHEntirelyWhenAccessTokenIsNil() async throws {
        let (sut, _) = makeSUT()

        let proof = try await sut.generate(htm: "POST", htu: Self.anyHTU, accessToken: nil)
        let segments = proof.value.split(separator: ".", omittingEmptySubsequences: false)
        let claimsData = try #require(String(segments[1]).base64URLDecodedData())
        let claimsJSON = try #require(JSONSerialization.jsonObject(with: claimsData) as? [String: Any])

        #expect(claimsJSON["ath"] == nil)
    }

    @Test
    func generateProducesASignatureThatVerifiesAgainstTheDevicePublicKey() async throws {
        let (sut, deviceKeyManager) = makeSUT()

        let proof = try await sut.generate(htm: "POST", htu: Self.anyHTU, accessToken: nil)
        let devicePublicKey = try await deviceKeyManager.publicKey

        let segments = proof.value.split(separator: ".", omittingEmptySubsequences: false)
        let signingInput = Data("\(segments[0]).\(segments[1])".utf8)
        let signatureData = try #require(String(segments[2]).base64URLDecodedData())

        let publicKey = try P256.Signing.PublicKey(x963Representation: devicePublicKey.rawPoint)
        let signature = try P256.Signing.ECDSASignature(rawRepresentation: signatureData)

        #expect(publicKey.isValidSignature(signature, for: signingInput))
    }
}

// MARK: - Factory methods

extension DPoPProofGeneratorTests {
    private func makeSUT() -> (sut: DPoPProofGenerator, deviceKeyManager: DeviceKeyManager) {
        let deviceKeyManager = DeviceKeyManager(privateKeyRepository: FakeDevicePrivateKeyRepository())
        return (DPoPProofGenerator(deviceKeyManager: deviceKeyManager), deviceKeyManager)
    }
}

// MARK: - Decoding helpers

extension DPoPProofGeneratorTests {
    private static let anyHTU = "https://api.tangem.com/mobile/token/refresh"

    private static func decodeHeader(from proof: DPoPProof) throws -> DecodedHeader {
        try decode(
            DecodedHeader.self,
            fromBase64URLSegment: proof.value.split(separator: ".", omittingEmptySubsequences: false)[0]
        )
    }

    private static func decodeClaims(from proof: DPoPProof) throws -> DecodedClaims {
        try decode(
            DecodedClaims.self,
            fromBase64URLSegment: proof.value.split(separator: ".", omittingEmptySubsequences: false)[1]
        )
    }

    private static func decode<T: Decodable>(_ type: T.Type, fromBase64URLSegment segment: some StringProtocol) throws -> T {
        let data = try #require(String(segment).base64URLDecodedData())
        return try JSONDecoder().decode(T.self, from: data)
    }

    /// Mirrors `DPoPProofGenerator.Header`'s wire shape for verification — kept `Decodable`-only and
    /// separate from production, since that type is deliberately `Encodable`-only (never decoded for real).
    private struct DecodedHeader: Decodable {
        let typ: String
        let alg: String
        let jwk: DecodedJWK
    }

    /// Mirrors `DPoPProofGenerator.JWK`'s wire shape for verification.
    private struct DecodedJWK: Decodable {
        let kty: String
        let crv: String
        let x: String
        let y: String
    }

    /// Mirrors `DPoPProofGenerator.Claims`'s wire shape for verification.
    private struct DecodedClaims: Decodable {
        let jti: String
        let htm: String
        let htu: String
        let iat: Int
        let ath: String?
    }
}
