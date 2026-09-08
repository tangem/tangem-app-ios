//
//  PolymarketL2AuthTests.swift
//  TangemPolymarketTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemPolymarket

@Suite("L2 authentication")
struct PolymarketL2AuthTests {
    private static let secret = "AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8="
    private static let baseURL = URL(string: "https://clob.polymarket.com")!

    // MARK: - The signature the exchange expects

    @Test("The signature matches the reference client", arguments: [
        Vector(
            secret: secret,
            timestamp: "1700000000",
            method: "GET",
            requestPath: "/order",
            body: "",
            signature: "pE_JGF8a0_X6nTMMD8ZNRmDXwtPNiD7XFQXAlTRuN8Q="
        ),
        Vector(
            secret: secret,
            timestamp: "1700000000",
            method: "POST",
            requestPath: "/order",
            body: "{\"a\":1}",
            signature: "uBmRP7BjQtWls1fT877WgPByC-SiSnPQJFihV7H5eUM="
        ),
        Vector(
            secret: secret,
            timestamp: "1700000000",
            method: "GET",
            requestPath: "/balance-allowance/update",
            body: "",
            signature: "HYThrzuMjEOc4dkcb09p7taGRQiJyCU75VyT_cIrXnE="
        ),
        Vector(
            secret: "-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_",
            timestamp: "1700000000",
            method: "GET",
            requestPath: "/order",
            body: "",
            signature: "lMBf4WgRKT3_qLflD-0AftEGiUDIrZOCdc-ZwWmQUx4="
        ),
    ])
    func signatureMatchesTheVector(vector: Vector) throws {
        let signature = try PolymarketL2Auth.signature(
            secret: vector.secret,
            timestamp: vector.timestamp,
            method: vector.method,
            requestPath: vector.requestPath,
            body: vector.body
        )

        #expect(signature == vector.signature)
    }

    @Test("The path is signed verbatim, so a query in it changes the signature")
    func theQueryChangesTheSignature() throws {
        let signed = try PolymarketL2Auth.signature(
            secret: Self.secret,
            timestamp: "1700000000",
            method: "GET",
            requestPath: "/balance-allowance/update"
        )

        let withQuery = try PolymarketL2Auth.signature(
            secret: Self.secret,
            timestamp: "1700000000",
            method: "GET",
            requestPath: "/balance-allowance/update?asset_type=COLLATERAL&signature_type=3"
        )

        #expect(signed == "HYThrzuMjEOc4dkcb09p7taGRQiJyCU75VyT_cIrXnE=")
        #expect(signed != withQuery)
    }

    @Test(
        "The path a CLOB target hands to the signature never carries a query",
        arguments: [
            PolymarketCLOBTarget.Target.createCredentials,
            .deriveCredentials,
            .updateBalanceAllowance,
            .balanceAllowance,
        ]
    )
    func signedPathCarriesNoQuery(target: PolymarketCLOBTarget.Target) {
        let sut = PolymarketCLOBTarget(baseURL: Self.baseURL, target: target, authHeaders: [:])

        #expect(!sut.signedPath.contains("?"))
    }

    @Test("A secret that is not base64url is rejected instead of signing with the wrong key")
    func malformedSecretIsRejected() {
        #expect(throws: PolymarketL2AuthError.invalidSecret) {
            try PolymarketL2Auth.signature(
                secret: "not base64!",
                timestamp: "1700000000",
                method: "GET",
                requestPath: "/order"
            )
        }
    }

    // MARK: - The headers the request carries

    @Test("The headers carry the credentials and the timestamp that was signed")
    func headersCarryTheCredentials() throws {
        let headers = try PolymarketL2Auth.headers(
            credentials: PolymarketL2Credentials(apiKey: "key", secret: Self.secret, passphrase: "phrase"),
            ownerAddress: "0xfAeA0f08159fcF2f573fE24E9E989B0d48f7651B",
            timestamp: "1700000000",
            method: "GET",
            requestPath: "/balance-allowance/update"
        )

        #expect(headers.values["POLY_ADDRESS"] == "0xfAeA0f08159fcF2f573fE24E9E989B0d48f7651B")
        #expect(headers.values["POLY_TIMESTAMP"] == "1700000000")
        #expect(headers.values["POLY_API_KEY"] == "key")
        #expect(headers.values["POLY_PASSPHRASE"] == "phrase")
        #expect(headers.values["POLY_SIGNATURE"] == "HYThrzuMjEOc4dkcb09p7taGRQiJyCU75VyT_cIrXnE=")
    }
}

// MARK: - Fixtures

extension PolymarketL2AuthTests {
    struct Vector: Sendable {
        let secret: String
        let timestamp: String
        let method: String
        let requestPath: String
        let body: String
        let signature: String
    }
}
