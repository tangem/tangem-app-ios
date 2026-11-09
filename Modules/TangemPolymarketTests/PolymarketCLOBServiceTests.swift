//
//  PolymarketCLOBServiceTests.swift
//  TangemPolymarketTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import Moya
import TangemNetworkUtils
@testable import TangemPolymarket

@Suite("Polymarket CLOB service order placement", .timeLimit(.minutes(1)))
struct PolymarketCLOBServicePlaceOrderTests {
    @Test("The order goes out signed over exactly the bytes that are sent, with every L2 header")
    func signatureCoversTheSentBody() async throws {
        let baseURL = PolymarketStubURLProtocol.makeBaseURL(answering: .init(body: Self.acceptedResponse))

        _ = try await Self.makeService(baseURL: baseURL).placeOrder(
            Self.signedOrder,
            credentials: Self.credentials,
            ownerAddress: Self.ownerAddress
        )

        let requests = PolymarketStubURLProtocol.sentRequests(to: baseURL)
        #expect(requests.count == 1)

        let sent = try #require(requests.first)
        let timestamp = try #require(sent.header("POLY_TIMESTAMP"))
        let json = try #require(try JSONSerialization.jsonObject(with: sent.body) as? [String: Any])
        let order = try #require(json["order"] as? [String: Any])

        let expectedSignature = try PolymarketL2Auth.signature(
            secret: Self.credentials.secret,
            timestamp: timestamp,
            method: "POST",
            requestPath: "/order",
            body: String(decoding: sent.body, as: UTF8.self)
        )

        #expect(sent.method == "POST")
        #expect(sent.url?.path == "/order")
        #expect(json["owner"] as? String == Self.credentials.apiKey)
        #expect(order["signature"] as? String == Self.signedOrder.signature)
        #expect(sent.header("POLY_SIGNATURE") == expectedSignature)
        #expect(sent.header("POLY_ADDRESS") == Self.ownerAddress)
        #expect(sent.header("POLY_API_KEY") == Self.credentials.apiKey)
        #expect(sent.header("POLY_PASSPHRASE") == Self.credentials.passphrase)
    }

    @Test("A success status that reports a failure inside is a rejection with the exchange's reason")
    func unsuccessfulAnswerIsRejected() async {
        let baseURL = PolymarketStubURLProtocol.makeBaseURL(
            answering: .init(body: #"{"success":false,"errorMsg":"not enough balance / allowance"}"#)
        )

        let error = await Self.placementError(baseURL: baseURL)

        guard case .rejected(let message) = error else {
            Issue.record("Expected a rejection, got \(String(describing: error))")
            return
        }

        #expect(message == "not enough balance / allowance")
    }

    @Test("A success status with a body that cannot be read is ambiguous, so the order is never offered twice")
    func unreadableAnswerIsAmbiguous() async {
        let baseURL = PolymarketStubURLProtocol.makeBaseURL(answering: .init(body: "<html>gateway</html>"))

        let error = await Self.placementError(baseURL: baseURL)

        guard case .ambiguous = error else {
            Issue.record("Expected an ambiguous outcome, got \(String(describing: error))")
            return
        }
    }
}

// MARK: - Fixtures

private extension PolymarketCLOBServicePlaceOrderTests {
    static let ownerAddress = "0x4130EFA9E628A991520BE60F2E948A4F9BE52FBC"

    static let credentials = PolymarketL2Credentials(
        apiKey: "api-key",
        secret: "AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8=",
        passphrase: "passphrase"
    )

    static let acceptedResponse = """
    {"errorMsg":"","orderID":"0xf1503cb4","takingAmount":"7.692306","makingAmount":"0.999999",
    "status":"matched","transactionsHashes":["0x7365a3d2"],"success":true}
    """

    static let signedOrder = PolymarketSignedOrder(
        order: PolymarketOrder(
            salt: 1_234_567_890,
            maker: "0x5A057dc6394196fBa51D84457DA3FB8FA241Fc20",
            signer: "0x5A057dc6394196fBa51D84457DA3FB8FA241Fc20",
            tokenId: "47",
            makerAmount: "72000000",
            takerAmount: "97959180",
            side: .buy,
            timestampMillis: 1_787_300_000_000,
            builder: "0x00000000000000000000000000000000000000000000000000000000000000aa"
        ),
        signature: "0xdeadbeef"
    )

    static func makeService(baseURL: URL) -> CommonPolymarketCLOBService {
        CommonPolymarketCLOBService(
            provider: TangemProvider(configuration: PolymarketStubURLProtocol.makeConfiguration()),
            baseURL: baseURL
        )
    }

    static func placementError(baseURL: URL) async -> PolymarketOrderPlacementError? {
        do {
            _ = try await makeService(baseURL: baseURL).placeOrder(
                signedOrder,
                credentials: credentials,
                ownerAddress: ownerAddress
            )
            return nil
        } catch let error as PolymarketOrderPlacementError {
            return error
        } catch {
            Issue.record("Expected a placement error, got \(error)")
            return nil
        }
    }
}
