//
//  PolymarketStubURLProtocol.swift
//  TangemPolymarketTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemNetworkUtils

final class PolymarketStubURLProtocol: URLProtocol {
    struct Response: Sendable {
        let statusCode: Int
        let body: Data

        init(statusCode: Int = 200, body: String) {
            self.statusCode = statusCode
            self.body = Data(body.utf8)
        }
    }

    struct SentRequest: Sendable {
        let url: URL?
        let method: String?
        let headers: [String: String]
        let body: Data

        func header(_ name: String) -> String? {
            headers.first { $0.key.caseInsensitiveCompare(name) == .orderedSame }?.value
        }
    }

    private struct Route: Sendable {
        let response: Response
        var sent: [SentRequest]
    }

    private static let routes = OSAllocatedUnfairLock(initialState: [String: Route]())

    static func makeBaseURL(answering response: Response) -> URL {
        let host = "\(UUID().uuidString.lowercased()).polymarket.test"
        routes.withLock { $0[host] = Route(response: response, sent: []) }
        return URL(string: "https://\(host)")!
    }

    static func sentRequests(to baseURL: URL) -> [SentRequest] {
        guard let host = baseURL.host else {
            return []
        }

        return routes.withLock { $0[host]?.sent ?? [] }
    }

    static func makeConfiguration() -> TangemProviderConfiguration {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [PolymarketStubURLProtocol.self]

        return TangemProviderConfiguration(logOptions: nil, urlSessionConfiguration: configuration)
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let url = request.url, let host = url.host else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }

        let sent = SentRequest(
            url: url,
            method: request.httpMethod,
            headers: request.allHTTPHeaderFields ?? [:],
            body: Self.readBody(of: request)
        )

        let response = Self.routes.withLock { routes -> Response? in
            routes[host]?.sent.append(sent)
            return routes[host]?.response
        }

        guard let response else {
            client?.urlProtocol(self, didFailWithError: URLError(.cannotFindHost))
            return
        }

        let httpResponse = HTTPURLResponse(
            url: url,
            statusCode: response.statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!

        client?.urlProtocol(self, didReceive: httpResponse, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: response.body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

// MARK: - Private implementation

private extension PolymarketStubURLProtocol {
    static func readBody(of request: URLRequest) -> Data {
        if let body = request.httpBody {
            return body
        }

        guard let stream = request.httpBodyStream else {
            return Data()
        }

        stream.open()
        defer { stream.close() }

        var buffer = [UInt8](repeating: 0, count: 16 * 1024)
        var collected = Data()

        while stream.hasBytesAvailable {
            let read = stream.read(&buffer, maxLength: buffer.count)

            guard read > 0 else {
                break
            }

            collected.append(buffer, count: read)
        }

        return collected
    }
}
