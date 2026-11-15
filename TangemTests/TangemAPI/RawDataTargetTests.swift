//
//  RawDataTargetTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Testing
import TangemNetworkUtils
@testable import Tangem

@Suite("Raw data target", .timeLimit(.minutes(1)))
struct RawDataTargetTests {
    @Test("A 2xx response hands back its body untouched")
    func successfulResponseReturnsBody() async throws {
        let url = try makeURL(statusCode: 200)

        let response = try await makeSUT().asyncRequest(RawDataTarget(url: url))

        #expect(response.data == RawDataURLProtocolStub.body)
    }

    @Test("A response outside 2xx fails instead of handing its body to the caller", arguments: [300, 404, 500])
    func nonSuccessResponseFails(statusCode: Int) async throws {
        let sut = makeSUT()
        let target = try RawDataTarget(url: makeURL(statusCode: statusCode))

        let error = try await #require(throws: MoyaError.self) {
            try await sut.asyncRequest(target)
        }

        #expect(error.response?.statusCode == statusCode)
    }
}

// MARK: - Helpers

private extension RawDataTargetTests {
    func makeSUT() -> TangemProvider<RawDataTarget> {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [RawDataURLProtocolStub.self]

        return TangemProvider(
            configuration: TangemProviderConfiguration(logOptions: nil, urlSessionConfiguration: configuration)
        )
    }

    func makeURL(statusCode: Int) throws -> URL {
        try #require(URL(string: "https://images.test/\(statusCode)"))
    }
}

// MARK: - Stubs

private final class RawDataURLProtocolStub: URLProtocol {
    static let body = Data("image".utf8)

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard
            let url = request.url,
            let statusCode = Int(url.lastPathComponent),
            let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)
        else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))

            return
        }

        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
