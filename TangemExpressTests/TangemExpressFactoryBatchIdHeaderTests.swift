//
//  TangemExpressFactoryBatchIdHeaderTests.swift
//  TangemExpressTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
@testable import TangemExpress

@Suite("Express API provider — batch-id header", .timeLimit(.minutes(1)))
struct TangemExpressFactoryBatchIdHeaderTests {
    @Test("Swap requests carry the card batch in the batch-id header", arguments: [false, true])
    func requestsCarryBatchId(isAPIV2Enabled: Bool) async throws {
        let sessionId = UUID().uuidString
        let sut = makeSUT(sessionId: sessionId, batchId: "BB000057", isAPIV2Enabled: isAPIV2Enabled)

        _ = try await sut.providers(branches: [.swap])

        #expect(HeadersURLProtocolSpy.batchIdHeaders(sessionId: sessionId) == ["BB000057"])
    }

    @Test("Requests outside the swap set omit the batch-id header", arguments: [false, true])
    func requestsOutsideSwapSetOmitBatchId(isAPIV2Enabled: Bool) async throws {
        let sessionId = UUID().uuidString
        let sut = makeSUT(sessionId: sessionId, batchId: "BB000057", isAPIV2Enabled: isAPIV2Enabled)

        _ = try await sut.onrampCurrencies()

        #expect(HeadersURLProtocolSpy.batchIdHeaders(sessionId: sessionId) == [nil])
    }

    @Test("Swap requests omit the batch-id header without a batch", arguments: [false, true])
    func requestsOmitBatchIdWithoutBatch(isAPIV2Enabled: Bool) async throws {
        let sessionId = UUID().uuidString
        let sut = makeSUT(sessionId: sessionId, batchId: nil, isAPIV2Enabled: isAPIV2Enabled)

        _ = try await sut.providers(branches: [.swap])

        #expect(HeadersURLProtocolSpy.batchIdHeaders(sessionId: sessionId) == [nil])
    }
}

// MARK: - Helpers

private extension TangemExpressFactoryBatchIdHeaderTests {
    func makeSUT(sessionId: String, batchId: String?, isAPIV2Enabled: Bool) -> ExpressAPIProvider {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [HeadersURLProtocolSpy.self]

        return TangemExpressFactory().makeExpressAPIProvider(
            credential: ExpressAPICredential(apiKey: "", userId: "", sessionId: sessionId, refcode: nil, batchId: batchId),
            configuration: configuration,
            expressAPIType: .production,
            exchangeDataDecoder: ExchangeDataDecoderStub(),
            featureFlags: ExpressFeatureFlags(
                isAPIV2Enabled: isAPIV2Enabled
            ),
            requestInterceptor: nil
        )
    }
}

// MARK: - Stubs

private final class HeadersURLProtocolSpy: URLProtocol {
    private static let batchIdsBySessionId = OSAllocatedUnfairLock(initialState: [String: [String?]]())

    static func batchIdHeaders(sessionId: String) -> [String?] {
        batchIdsBySessionId.withLock { $0[sessionId] ?? [] }
    }

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let sessionId = request.value(forHTTPHeaderField: "session-id") ?? ""
        let batchId = request.value(forHTTPHeaderField: "batch-id")
        Self.batchIdsBySessionId.withLock { $0[sessionId, default: []].append(batchId) }

        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!

        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data("[]".utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

private struct ExchangeDataDecoderStub: ExpressExchangeDataDecoder {
    func decode<T: Decodable>(txDetailsJson: String, signature: String) throws -> T {
        throw NSError.dummy
    }
}
