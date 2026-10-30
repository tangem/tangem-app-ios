//
//  PolymarketSessionKeyServiceTests.swift
//  TangemPolymarketTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemNetworkUtils
@testable import TangemPolymarket

@Suite("Polymarket session key service", .timeLimit(.minutes(1)))
struct PolymarketSessionKeyServiceTests {
    @Test("The wallet's session keys are read from the wallet endpoint with the wallet id")
    func sessionKeysAreReadFromTheWallet() async throws {
        let (service, baseURL) = Self.makeService(answering: .init(body: """
        {"status":"READY_TO_TRADE","sessionKeys":[{"address":"0x5E55000000000000000000000000000000000001","status":"ACTIVE"}]}
        """))

        let keys = try await service.sessionKeys()

        let sent = try #require(PolymarketStubURLProtocol.sentRequests(to: baseURL).first)
        let query = URLComponents(url: try #require(sent.url), resolvingAgainstBaseURL: false)?.queryItems

        #expect(sent.method == "GET")
        #expect(sent.url?.path == "/api/predictions/v1/wallet")
        #expect(query == [URLQueryItem(name: "walletId", value: Self.walletId)])
        #expect(sent.header("wallet-id") == Self.walletId)
        #expect(keys.map(\.address) == ["0x5e55000000000000000000000000000000000001"])
        #expect(keys.map(\.status) == [.active])
    }

    @Test("An authorization posts the owner's signed batch with the key, the device and the validity as a string")
    func authorizationPostsTheSignedBatch() async throws {
        let (service, baseURL) = Self.makeService(answering: .init(body: #"{"address":"0x5e55","status":"PENDING"}"#))

        let key = try await service.authorize(PolymarketSessionKeyAuthorization(
            batch: Self.batch,
            sessionKeyAddress: "0x5e55",
            deviceId: "device-1",
            deviceName: "iPhone 17 Pro",
            validUntil: Date(timeIntervalSince1970: 1_804_982_400),
            replacesSessionKeyAddress: "0x01d0"
        ))

        let sent = try #require(PolymarketStubURLProtocol.sentRequests(to: baseURL).first)
        let body = try #require(try JSONSerialization.jsonObject(with: sent.body) as? [String: Any])

        #expect(sent.method == "POST")
        #expect(sent.url?.path == "/api/predictions/v1/wallet/session-keys")
        #expect(body["ownerAddress"] as? String == Self.batch.ownerAddress)
        #expect(body["depositWalletAddress"] as? String == Self.batch.depositWalletAddress)
        #expect(body["sessionKeyAddress"] as? String == "0x5e55")
        #expect(body["deviceId"] as? String == "device-1")
        #expect(body["deviceName"] as? String == "iPhone 17 Pro")
        #expect(body["validUntil"] as? String == "1804982400")
        #expect(body["nonce"] as? String == Self.batch.nonce)
        #expect(body["deadline"] as? String == Self.batch.deadline)
        #expect(body["signature"] as? String == Self.batch.signature)
        #expect(body["replacesSessionKeyAddress"] as? String == "0x01d0")
        #expect((body["calls"] as? [[String: String]]) == [["target": "0xdef0", "value": "0", "data": "0x24017fae"]])
        #expect(key.status == .pending)
    }

    @Test("A revocation posts the owner's signed batch for the key to the revocations endpoint")
    func revocationPostsTheSignedBatch() async throws {
        let (service, baseURL) = Self.makeService(answering: .init(body: #"{"address":"0x5e55","status":"REVOKING"}"#))

        _ = try await service.revoke(PolymarketSessionKeyRevocation(batch: Self.batch, sessionKeyAddress: "0x5e55"))

        let sent = try #require(PolymarketStubURLProtocol.sentRequests(to: baseURL).first)
        let body = try #require(try JSONSerialization.jsonObject(with: sent.body) as? [String: Any])

        #expect(sent.method == "POST")
        #expect(sent.url?.path == "/api/predictions/v1/wallet/session-keys/revocations")
        #expect(body["ownerAddress"] as? String == Self.batch.ownerAddress)
        #expect(body["depositWalletAddress"] as? String == Self.batch.depositWalletAddress)
        #expect(body["sessionKeyAddress"] as? String == "0x5e55")
        #expect(body["nonce"] as? String == Self.batch.nonce)
        #expect(body["deadline"] as? String == Self.batch.deadline)
        #expect(body["signature"] as? String == Self.batch.signature)
        #expect((body["calls"] as? [[String: String]]) == [["target": "0xdef0", "value": "0", "data": "0x24017fae"]])
        #expect(body.count == 7)
    }

    @Test("An answer of an unexpected shape is reported as a decoding failure, not as a lost connection")
    func malformedAnswerIsADecodingFailure() async {
        let (service, _) = Self.makeService(answering: .init(body: #"{"unexpected":true}"#))

        do {
            _ = try await service.revoke(PolymarketSessionKeyRevocation(batch: Self.batch, sessionKeyAddress: "0x5e55"))
            Issue.record("Expected a decoding failure")
        } catch {
            guard case .other(.decoding) = error else {
                Issue.record("Expected a decoding failure, got \(error)")
                return
            }
        }
    }

    @Test("Pausing a key puts the flag on the key's own address, without a signature")
    func pauseTogglesTheKeyItself() async throws {
        let (service, baseURL) = Self.makeService(answering: .init(body: #"{"address":"0x5e55","status":"ACTIVE","enabled":false}"#))

        let key = try await service.setEnabled(false, sessionKeyAddress: "0x5e55")

        let sent = try #require(PolymarketStubURLProtocol.sentRequests(to: baseURL).first)
        let body = try #require(try JSONSerialization.jsonObject(with: sent.body) as? [String: Bool])

        #expect(sent.method == "PUT")
        #expect(sent.url?.path == "/api/predictions/v1/wallet/session-keys/0x5e55/enabled")
        #expect(body == ["enabled": false])
        #expect(!key.isEnabled)
    }

    @Test("A refusal reaches the caller with the backend's reason")
    func refusalCarriesTheReason() async {
        let (service, _) = Self.makeService(answering: .init(
            statusCode: 409,
            body: #"{"status":409,"reason":"DEVICE_HAS_SESSION_KEY","detail":"Device already has an active session key"}"#
        ))

        do {
            _ = try await service.setEnabled(true, sessionKeyAddress: "0x5e55")
            Issue.record("Expected a refusal")
        } catch {
            guard case .refused(let statusCode, let reason, _) = error else {
                Issue.record("Expected a refusal, got \(error)")
                return
            }

            #expect(statusCode == 409)
            #expect(reason == .deviceHasSessionKey)
        }
    }
}

// MARK: - Fixtures

private extension PolymarketSessionKeyServiceTests {
    static let walletId = "wallet-1"

    static let batch = PolymarketRelayedBatch(
        ownerAddress: "0x0aaa000000000000000000000000000000000001",
        depositWalletAddress: "0xdef0000000000000000000000000000000000002",
        nonce: "7",
        deadline: "1789430400",
        calls: [PolymarketRelayedBatch.Call(target: "0xdef0", data: "0x24017fae")],
        signature: "0x51"
    )

    static func makeService(answering response: PolymarketStubURLProtocol.Response) -> (any PolymarketSessionKeyService, URL) {
        let baseURL = PolymarketStubURLProtocol.makeBaseURL(answering: response)
        let service = CommonPolymarketSessionKeyService(
            provider: TangemProvider(configuration: PolymarketStubURLProtocol.makeConfiguration()),
            environment: { PolymarketBFFEnvironment(baseURL: baseURL, headers: [:]) },
            walletId: walletId
        )

        return (service, baseURL)
    }
}
