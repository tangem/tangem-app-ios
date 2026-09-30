//
//  MoralisEVMNFTNetworkServicePaginationTests.swift
//  TangemModules
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import os
import Testing
import TangemNetworkUtils
@testable import TangemNFT

@Suite("MoralisEVMNFTNetworkService — pagination", .serialized, .timeLimit(.minutes(1)))
struct MoralisEVMNFTNetworkServicePaginationTests {
    private let walletAddress = "0x000000000000000000000000000000000000dead"

    @Test("A failing non-first page stops pagination and is reported as a partial result")
    func failingPageStopsPagination() async throws {
        StubURLProtocol.reset()
        StubURLProtocol.handler = { request in
            let cursor = request.url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }?
                .queryItems?
                .first { $0.name == "cursor" }?
                .value

            switch cursor {
            case nil:
                return (200, Self.page(cursor: "page-2", tokenAddress: "0x0000000000000000000000000000000000000001"))
            default:
                return (429, Data(#"{"message":"Too many requests"}"#.utf8))
            }
        }

        let result = await makeService().getCollections(address: walletAddress)

        // Before the fix the failed page was re-requested with the same cursor forever.
        #expect(StubURLProtocol.requestCount() == 2)
        #expect(result.value.count == 1)
        #expect(result.value.first?.id.collectionIdentifier == "0x0000000000000000000000000000000000000001")
        #expect(result.errors.count == 1)
        #expect(result.errors.first?.description == "Too many requests")
    }

    @Test("All pages are collected when every request succeeds")
    func successfulPagesAreCollected() async throws {
        StubURLProtocol.reset()
        StubURLProtocol.handler = { request in
            let cursor = request.url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }?
                .queryItems?
                .first { $0.name == "cursor" }?
                .value

            switch cursor {
            case nil:
                return (200, Self.page(cursor: "page-2", tokenAddress: "0x0000000000000000000000000000000000000001"))
            case "page-2":
                return (200, Self.page(cursor: nil, tokenAddress: "0x0000000000000000000000000000000000000002"))
            default:
                Issue.record("unexpected cursor \(String(describing: cursor))")
                return (500, Data())
            }
        }

        let result = await makeService().getCollections(address: walletAddress)

        #expect(StubURLProtocol.requestCount() == 2)
        #expect(result.value.map(\.id.collectionIdentifier) == [
            "0x0000000000000000000000000000000000000001",
            "0x0000000000000000000000000000000000000002",
        ])
        #expect(result.errors.isEmpty)
    }

    private func makeService() -> MoralisEVMNFTNetworkService {
        let sessionConfiguration = URLSessionConfiguration.ephemeral
        sessionConfiguration.protocolClasses = [StubURLProtocol.self]

        return MoralisEVMNFTNetworkService(
            networkConfiguration: TangemProviderConfiguration(logOptions: nil, urlSessionConfiguration: sessionConfiguration),
            headers: [],
            chain: .ethereum(isTestnet: false)
        )
    }

    private static func page(cursor: String?, tokenAddress: String) -> Data {
        let cursorJSON = cursor.map { "\"\($0)\"" } ?? "null"
        return Data(
            """
            {
              "page": 1,
              "page_size": 100,
              "cursor": \(cursorJSON),
              "result": [
                { "token_address": "\(tokenAddress)", "contract_type": "ERC721", "name": "Test", "count": 1 }
              ]
            }
            """.utf8
        )
    }
}

// MARK: - Test double

private final class StubURLProtocol: URLProtocol {
    typealias Handler = @Sendable (URLRequest) -> (statusCode: Int, body: Data)

    private struct State {
        var handler: Handler?
        var requestCount = 0
    }

    private static let state = OSAllocatedUnfairLock(initialState: State())

    static var handler: Handler? {
        get { state.withLock { $0.handler } }
        set { state.withLock { $0.handler = newValue } }
    }

    static func reset() {
        state.withLock { $0 = State() }
    }

    static func requestCount() -> Int {
        state.withLock { $0.requestCount }
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let handler = Self.state.withLock { state -> Handler? in
            state.requestCount += 1
            return state.handler
        }

        guard let handler, let url = request.url else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }

        let (statusCode, body) = handler(request)
        let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: "HTTP/1.1", headerFields: ["Content-Type": "application/json"])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
