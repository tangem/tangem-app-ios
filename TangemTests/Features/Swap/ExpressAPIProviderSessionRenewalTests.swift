//
//  ExpressAPIProviderSessionRenewalTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Alamofire
import Foundation
import Testing
import TangemExpress
import TangemFoundation

@Suite("Express API provider — session renewal on an unauthorized response", .timeLimit(.minutes(1)))
struct ExpressAPIProviderSessionRenewalTests {
    @Test("On v2 an unauthorized response reaches the interceptor, which repeats the request")
    func v2UnauthorizedResponseIsRetried() async throws {
        let sessionId = UUID().uuidString
        let interceptor = SessionRenewingInterceptorSpy()
        let sut = makeSUT(sessionId: sessionId, isAPIV2Enabled: true, interceptor: interceptor)

        _ = try await sut.providers(branches: [.swap])

        let url = try #require(URL(string: Constants.v2URL))
        #expect(interceptor.receivedMessages == [.adapt(url), .retry(statusCode: 401), .adapt(url)])
        #expect(UnauthorizedOnceURLProtocolStub.requestedURLs(sessionId: sessionId) == [url, url])
    }

    @Test("On v1 an unauthorized response never reaches the interceptor and comes back as the Express error")
    func v1UnauthorizedResponseIsNotRetried() async throws {
        let sessionId = UUID().uuidString
        let interceptor = SessionRenewingInterceptorSpy()
        let sut = makeSUT(sessionId: sessionId, isAPIV2Enabled: false, interceptor: interceptor)

        let error = try await #require(throws: ExpressAPIError.self) {
            _ = try await sut.providers(branches: [.swap])
        }

        let url = try #require(URL(string: Constants.v1URL))
        #expect(error.code == 2264)
        #expect(interceptor.receivedMessages == [.adapt(url)])
        #expect(UnauthorizedOnceURLProtocolStub.requestedURLs(sessionId: sessionId) == [url])
    }
}

// MARK: - Helpers

private extension ExpressAPIProviderSessionRenewalTests {
    enum Constants {
        static let v1URL = "https://express.tangem.com/v1/providers"
        static let v2URL = "https://express.tangem.com/v2/providers"
    }

    func makeSUT(sessionId: String, isAPIV2Enabled: Bool, interceptor: some RequestInterceptor) -> ExpressAPIProvider {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [UnauthorizedOnceURLProtocolStub.self]

        return TangemExpressFactory().makeExpressAPIProvider(
            credential: ExpressAPICredential(apiKey: "", userId: "", sessionId: sessionId, refcode: nil),
            configuration: configuration,
            expressAPIType: .production,
            exchangeDataDecoder: ExchangeDataDecoderStub(),
            featureFlags: ExpressFeatureFlags(
                isAPIV2Enabled: isAPIV2Enabled
            ),
            requestInterceptor: interceptor
        )
    }
}

// MARK: - Stubs

private final class SessionRenewingInterceptorSpy: RequestInterceptor, Sendable {
    private let messages = OSAllocatedUnfairLock(initialState: [Message]())

    var receivedMessages: [Message] {
        messages.withLock { $0 }
    }

    func adapt(
        _ urlRequest: URLRequest,
        for session: Session,
        completion: @escaping @Sendable (Result<URLRequest, any Error>) -> Void
    ) {
        let url = urlRequest.url
        messages.withLock { $0.append(.adapt(url)) }
        completion(.success(urlRequest))
    }

    func retry(
        _ request: Request,
        for session: Session,
        dueTo error: any Error,
        completion: @escaping @Sendable (RetryResult) -> Void
    ) {
        let statusCode = request.response?.statusCode
        messages.withLock { $0.append(.retry(statusCode: statusCode)) }
        completion(statusCode == 401 && request.retryCount == 0 ? .retry : .doNotRetry)
    }
}

extension SessionRenewingInterceptorSpy {
    enum Message: Equatable {
        case adapt(URL?)
        case retry(statusCode: Int?)
    }
}

private final class UnauthorizedOnceURLProtocolStub: URLProtocol {
    private static let urlsBySessionId = OSAllocatedUnfairLock(initialState: [String: [URL?]]())

    static func requestedURLs(sessionId: String) -> [URL?] {
        urlsBySessionId.withLock { $0[sessionId] ?? [] }
    }

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let sessionId = request.value(forHTTPHeaderField: "session-id") ?? ""
        let url = request.url
        let isFirstRequest = Self.urlsBySessionId.withLock { urls in
            urls[sessionId, default: []].append(url)
            return urls[sessionId]?.count == 1
        }

        let statusCode = isFirstRequest ? 401 : 200
        let body = isFirstRequest ? #"{"error":{"code":2264,"description":"Unauthorized"}}"# : "[]"
        let response = HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: nil)!

        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

private struct ExchangeDataDecoderStub: ExpressExchangeDataDecoder {
    func decode<T: Decodable>(txDetailsJson: String, signature: String) throws -> T {
        throw NSError.dummy
    }
}
