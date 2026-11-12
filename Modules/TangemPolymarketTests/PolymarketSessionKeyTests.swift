//
//  PolymarketSessionKeyTests.swift
//  TangemPolymarketTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import Moya
@testable import TangemPolymarket

@Suite("Polymarket session key mapping", .timeLimit(.minutes(1)))
struct PolymarketSessionKeyMappingTests {
    @Test("A wallet's session keys are mapped with a lowercased address and every field the backend sent")
    func fullKey() throws {
        let keys = try Self.mapKeys("""
        {
            "depositWalletAddress": "0xdef0000000000000000000000000000000000002",
            "status": "READY_TO_TRADE",
            "sessionKeys": [
                {
                    "address": "0x5E55000000000000000000000000000000000001",
                    "deviceId": "3f2b8c1e",
                    "deviceName": "iPhone 15 Pro",
                    "enabled": true,
                    "status": "ACTIVE",
                    "scopes": ["CLOB"],
                    "validUntil": 1804982400,
                    "renewAfter": 1804723200,
                    "authorizedAt": 1789430400,
                    "createdAt": 1789430280
                }
            ]
        }
        """)

        #expect(keys == [
            PolymarketSessionKey(
                address: "0x5e55000000000000000000000000000000000001",
                deviceId: "3f2b8c1e",
                deviceName: "iPhone 15 Pro",
                isEnabled: true,
                status: .active,
                scopes: ["CLOB"],
                validUntil: Date(timeIntervalSince1970: 1_804_982_400),
                authorizedAt: Date(timeIntervalSince1970: 1_789_430_400),
                createdAt: Date(timeIntervalSince1970: 1_789_430_280)
            ),
        ])
    }

    @Test("A key that is not authorized yet maps without dates, scopes or device and is not enabled")
    func missingOptionalFields() throws {
        let keys = try Self.mapKeys("""
        {
            "status": "READY_TO_TRADE",
            "sessionKeys": [
                { "address": "0x01D0000000000000000000000000000000000009", "status": "PENDING", "validUntil": null }
            ]
        }
        """)

        let key = try #require(keys.first)
        #expect(key.address == "0x01d0000000000000000000000000000000000009")
        #expect(key.status == .pending)
        #expect(!key.isEnabled)
        #expect(key.scopes.isEmpty)
        #expect(key.deviceId == nil)
        #expect(key.deviceName == nil)
        #expect(key.validUntil == nil)
        #expect(key.authorizedAt == nil)
        #expect(key.createdAt == nil)
    }

    @Test("A wallet answered by a backend without session keys has none")
    func missingSessionKeys() throws {
        let keys = try Self.mapKeys(#"{"depositWalletAddress":"0x1","status":"READY_TO_TRADE"}"#)

        #expect(keys.isEmpty)
    }

    @Test("A status is read regardless of case and an unfamiliar one keeps its raw value", arguments: [
        ("REVOKING", PolymarketSessionKey.Status.revoking),
        ("expired", .expired),
        ("Failed", .failed),
        ("SUSPENDED", .unknown("SUSPENDED")),
    ])
    func status(_ raw: String, _ expected: PolymarketSessionKey.Status) throws {
        let keys = try Self.mapKeys(#"{"status":"READY_TO_TRADE","sessionKeys":[{"address":"0x1","status":"\#(raw)"}]}"#)

        #expect(keys.first?.status == expected)
    }

    private static func mapKeys(_ json: String) throws -> [PolymarketSessionKey] {
        let dto = try JSONDecoder().decode(PolymarketDTO.WalletStatusResponse.self, from: Data(json.utf8))
        return (dto.sessionKeys ?? []).map(PolymarketMapper().mapSessionKey)
    }
}

@Suite("Polymarket session key errors", .timeLimit(.minutes(1)))
struct PolymarketSessionKeyErrorTests {
    @Test("A refusal carries the reason code and detail from the backend's problem body")
    func refusalFromProblemBody() throws {
        let error = Self.sessionKeyError(statusCode: 409, body: """
        {
            "type": "about:blank",
            "title": "Conflict",
            "status": 409,
            "detail": "Device already has an active session key",
            "instance": "/api/predictions/v1/wallet/session-keys",
            "reason": "DEVICE_HAS_SESSION_KEY",
            "traceId": "4bf92f3577b34da6"
        }
        """)

        guard case .refused(let statusCode, let reason, let detail) = error else {
            Issue.record("Expected a refusal, got \(error)")
            return
        }

        #expect(statusCode == 409)
        #expect(reason == .deviceHasSessionKey)
        #expect(detail == "Device already has an active session key")
    }

    @Test("A refusal with an unfamiliar or missing reason keeps whatever the backend sent", arguments: [
        (#"{"status":409,"reason":"SESSION_KEY_FROZEN"}"#, PolymarketSessionKeyError.Reason.unknown("SESSION_KEY_FROZEN")),
        (#"{"status":409,"title":"Conflict"}"#, .unknown(nil)),
        ("upstream exploded", .unknown(nil)),
    ])
    func unfamiliarReason(_ body: String, _ expected: PolymarketSessionKeyError.Reason) {
        guard case .refused(_, let reason, _) = Self.sessionKeyError(statusCode: 409, body: body) else {
            Issue.record("Expected a refusal")
            return
        }

        #expect(reason == expected)
    }

    @Test("Only a server outage, a lost connection, a timeout or throttling invites the same request again", arguments: [
        (PolymarketAPIError.http(statusCode: 502, problemDetail: nil), true),
        (.http(statusCode: 503, problemDetail: nil), true),
        (.http(statusCode: 408, problemDetail: nil), true),
        (.http(statusCode: 429, problemDetail: nil), true),
        (.http(statusCode: 422, problemDetail: nil), false),
        (.connection(underlying: URLError(.networkConnectionLost)), true),
        (.decoding(field: "status", value: "?"), false),
    ])
    func retryable(_ apiError: PolymarketAPIError, _ isRetryable: Bool) {
        #expect(PolymarketSessionKeyError(apiError: apiError).isRetryableWithTheSameRequest == isRetryable)
    }

    @Test("Only a 4xx answer counts as the backend refusing the client", arguments: [
        (PolymarketAPIError.http(statusCode: 399, problemDetail: nil), false),
        (.http(statusCode: 400, problemDetail: nil), true),
        (.http(statusCode: 499, problemDetail: nil), true),
        (.http(statusCode: 500, problemDetail: nil), false),
        (.connection(underlying: URLError(.notConnectedToInternet)), false),
        (.decoding(field: "status", value: "?"), false),
    ])
    func clientRefusal(_ apiError: PolymarketAPIError, _ isClientRefusal: Bool) {
        #expect(apiError.isClientRefusal == isClientRefusal)
    }

    private static func sessionKeyError(statusCode: Int, body: String) -> PolymarketSessionKeyError {
        let moyaError = MoyaError.statusCode(Response(statusCode: statusCode, data: Data(body.utf8)))
        return PolymarketSessionKeyError(apiError: CommonPolymarketAPIService.mapMoyaError(moyaError, decoder: JSONDecoder()))
    }
}

@Suite("Polymarket session signers mapping", .timeLimit(.minutes(1)))
struct PolymarketSessionSignersTests {
    @Test("Signers are mapped with lowercased addresses and the expiry read as a number or a string")
    func signers() throws {
        let signers = try Self.mapSigners("""
        {
            "wallet": "0xdef0000000000000000000000000000000000002",
            "signers": [
                { "address": "0x5E55000000000000000000000000000000000001", "scopes": ["CLOB"], "valid_until": 1804982400 },
                { "address": "0x01d0000000000000000000000000000000000009", "scopes": ["ALL"], "valid_until": "1801353600" },
                { "address": "0x0000000000000000000000000000000000000003", "valid_until": null }
            ]
        }
        """)

        #expect(signers == [
            PolymarketSessionSigner(
                address: "0x5e55000000000000000000000000000000000001",
                scopes: ["CLOB"],
                validUntil: Date(timeIntervalSince1970: 1_804_982_400)
            ),
            PolymarketSessionSigner(
                address: "0x01d0000000000000000000000000000000000009",
                scopes: ["ALL"],
                validUntil: Date(timeIntervalSince1970: 1_801_353_600)
            ),
            PolymarketSessionSigner(address: "0x0000000000000000000000000000000000000003", scopes: [], validUntil: nil),
        ])
    }

    @Test("An expiry in an unexpected format fails the decoding instead of reading as no expiry", arguments: [
        "1804982400.5",
        #""2027-01-15T08:00:00Z""#,
        #""1804982400.0""#,
        "true",
    ])
    func unexpectedExpiryFails(_ validUntil: String) {
        #expect(throws: DecodingError.self) {
            try Self.mapSigners(#"{"signers":[{"address":"0x1","valid_until":\#(validUntil)}]}"#)
        }
    }

    @Test("A wallet without session signers yields an empty list")
    func missingSigners() throws {
        #expect(try Self.mapSigners(#"{"wallet":"0x1"}"#).isEmpty)
    }

    private static func mapSigners(_ json: String) throws -> [PolymarketSessionSigner] {
        let dto = try JSONDecoder().decode(PolymarketDTO.SessionSignersResponse.self, from: Data(json.utf8))
        return PolymarketMapper().mapSessionSigners(dto)
    }
}
