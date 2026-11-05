//
//  TangemExpressFactoryAPIVersionTests.swift
//  TangemExpressTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
@testable import TangemExpress

@Suite("Express API provider — API version", .timeLimit(.minutes(1)))
struct TangemExpressFactoryAPIVersionTests {
    @Test(
        "Requests go to the API version the flag selects",
        arguments: zip(
            [false, true],
            ["https://express.tangem.com/v1/providers", "https://express.tangem.com/v2/providers"]
        )
    )
    func requestsGoToSelectedVersion(isAPIV2Enabled: Bool, expectedURL: String) async throws {
        let sessionId = UUID().uuidString
        let sut = makeSUT(sessionId: sessionId, isAPIV2Enabled: isAPIV2Enabled)

        _ = try await sut.providers(branches: [.swap])

        let url = try #require(URL(string: expectedURL))
        #expect(ProvidersURLProtocolSpy.requestedURLs(sessionId: sessionId) == [url])
    }

    @Test("An unauthorized response still comes back as the Express error it carries", arguments: [false, true])
    func unauthorizedResponseIsMappedToExpressError(isAPIV2Enabled: Bool) async throws {
        let sut = makeSUT(isAPIV2Enabled: isAPIV2Enabled, urlProtocol: UnauthorizedURLProtocolStub.self)

        let error = try await #require(throws: ExpressAPIError.self) {
            _ = try await sut.providers(branches: [.swap])
        }

        #expect(error.code == 2264)
    }
}

// MARK: - Helpers

private extension TangemExpressFactoryAPIVersionTests {
    func makeSUT(
        sessionId: String = "",
        isAPIV2Enabled: Bool,
        urlProtocol: URLProtocol.Type = ProvidersURLProtocolSpy.self
    ) -> ExpressAPIProvider {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [urlProtocol]

        return TangemExpressFactory().makeExpressAPIProvider(
            credential: ExpressAPICredential(apiKey: "", userId: "", sessionId: sessionId, refcode: nil),
            configuration: configuration,
            expressAPIType: .production,
            exchangeDataDecoder: ExchangeDataDecoderStub(),
            featureFlags: ExpressFeatureFlags(
                isSwapBestRateDefaultProviderEnabled: false,
                isHideRejectedSwapProvidersEnabled: false,
                isAPIV2Enabled: isAPIV2Enabled
            ),
            requestInterceptor: nil
        )
    }
}

// MARK: - Stubs

private final class ProvidersURLProtocolSpy: URLProtocol {
    private static let urlsBySessionId = OSAllocatedUnfairLock(initialState: [String: [URL?]]())

    static func requestedURLs(sessionId: String) -> [URL?] {
        urlsBySessionId.withLock { $0[sessionId] ?? [] }
    }

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let sessionId = request.value(forHTTPHeaderField: "session-id") ?? ""
        let url = request.url
        Self.urlsBySessionId.withLock { $0[sessionId, default: []].append(url) }

        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!

        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data("[]".utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

private final class UnauthorizedURLProtocolStub: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let body = Data(#"{"error":{"code":2264,"description":"Unauthorized"}}"#.utf8)
        let response = HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!

        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

private struct ExchangeDataDecoderStub: ExpressExchangeDataDecoder {
    func decode<T: Decodable>(txDetailsJson: String, signature: String) throws -> T {
        throw NSError.dummy
    }
}
