//
//  MoyaMCPSendIntentClientTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import Alamofire
import Moya
import TangemFoundation
@testable import Tangem

struct MoyaMCPSendIntentClientTests {
    // MARK: - Fetch

    @Test
    func fetchRequestsIntentByIdAsReceived() async throws {
        let requestRecorder = RequestRecorder()
        let sut = try Self.makeSUT(statusCode: 200, responseBody: Fixture.intentJSON(type: "SEND"), requestRecorder: requestRecorder)

        _ = try await sut.fetch(intentId: Fixture.intentId.uppercased())

        let request = try #require(requestRecorder.requests.first)
        #expect(requestRecorder.requests.count == 1)
        #expect(request.httpMethod == "GET")
        #expect(request.url?.path == "/api/transactions/v1/intents/\(Fixture.intentId.uppercased())")
    }

    @Test
    func fetchMapsResponse() async throws {
        let sut = try Self.makeSUT(statusCode: 200, responseBody: Fixture.intentJSON(type: "SEND"))

        let intent = try await sut.fetch(intentId: Fixture.intentId)

        #expect(
            intent == SendMCPIntent(
                id: Fixture.intentId,
                networkID: "ethereum",
                tokenID: "ethereum",
                fromAddress: "0xe34979ea46a0bb49f0e483f163c79be02101cd1b",
                toAddress: "0x1111111111111111111111111111111111111111",
                amount: Decimal(string: "0.000001", locale: Locale(identifier: "en_US_POSIX"))!,
                memo: nil,
                isCompleted: false,
                agentID: "https://claude.ai/oauth/claude-code-client-metadata"
            )
        )
    }

    @Test(arguments: [
        "",
        "abc",
        "../intents",
        " 3f7c2a1e-9b4d-4c6a-8e21-5d0f7a9b1c33",
        "3f7c2a1e9b4d4c6a8e215d0f7a9b1c33",
        "3f7c2a1e-9b4d-4c6a-8e21-5d0f7a9b1c33/transaction",
    ])
    func fetchRejectsMalformedIdWithoutRequest(intentId: String) async throws {
        let requestRecorder = RequestRecorder()
        let sut = try Self.makeSUT(statusCode: 200, responseBody: Fixture.intentJSON(type: "SEND"), requestRecorder: requestRecorder)

        let error = try await #require(throws: SendMCPIntentError.self) {
            _ = try await sut.fetch(intentId: intentId)
        }

        guard case .invalidIntentId(intentId) = error else {
            Issue.record("Expected .invalidIntentId, got \(error)")
            return
        }
        #expect(requestRecorder.requests.isEmpty)
    }

    @Test(arguments: StatusCodes.error)
    func fetchThrowsRequestFailedOnErrorStatusCode(errorStatusCode: Int) async throws {
        let sut = try Self.makeSUT(statusCode: errorStatusCode, responseBody: Fixture.intentJSON(type: "SEND"))

        let error = try await #require(throws: SendMCPIntentError.self) {
            _ = try await sut.fetch(intentId: Fixture.intentId)
        }

        guard case .requestFailed = error else {
            Issue.record("Expected .requestFailed, got \(error)")
            return
        }
    }

    @Test
    func fetchThrowsTimeoutOnTimeoutNetworkError() async throws {
        let sut = try Self.makeSUT(networkError: AFError.sessionTaskFailed(error: URLError(.timedOut)))

        let error = try await #require(throws: SendMCPIntentError.self) {
            _ = try await sut.fetch(intentId: Fixture.intentId)
        }

        guard case .timeout = error else {
            Issue.record("Expected .timeout, got \(error)")
            return
        }
    }

    @Test(arguments: [URLError.Code.notConnectedToInternet, .dataNotAllowed, .networkConnectionLost])
    func fetchThrowsNoInternetConnectionOnMissingConnection(code: URLError.Code) async throws {
        let sut = try Self.makeSUT(networkError: AFError.sessionTaskFailed(error: URLError(code)))

        let error = try await #require(throws: SendMCPIntentError.self) {
            _ = try await sut.fetch(intentId: Fixture.intentId)
        }

        guard case .noInternetConnection = error else {
            Issue.record("Expected .noInternetConnection, got \(error)")
            return
        }
    }

    @Test
    func fetchThrowsRequestFailedOnOtherNetworkError() async throws {
        let sut = try Self.makeSUT(networkError: AFError.sessionTaskFailed(error: URLError(.cannotFindHost)))

        let error = try await #require(throws: SendMCPIntentError.self) {
            _ = try await sut.fetch(intentId: Fixture.intentId)
        }

        guard case .requestFailed = error else {
            Issue.record("Expected .requestFailed, got \(error)")
            return
        }
    }

    @Test(arguments: ["{not json", "{}", "[]", ""])
    func fetchThrowsRequestFailedOnUnreadableBody(responseBody: String) async throws {
        let sut = try Self.makeSUT(statusCode: 200, responseBody: responseBody)

        let error = try await #require(throws: SendMCPIntentError.self) {
            _ = try await sut.fetch(intentId: Fixture.intentId)
        }

        guard case .requestFailed(let underlying) = error, underlying is DecodingError else {
            Issue.record("Expected .requestFailed with a DecodingError, got \(error)")
            return
        }
    }

    @Test
    func fetchThrowsUnsupportedTypeForAnotherIntentType() async throws {
        let sut = try Self.makeSUT(statusCode: 200, responseBody: Fixture.intentJSON(type: "SWAP"))

        let error = try await #require(throws: SendMCPIntentError.self) {
            _ = try await sut.fetch(intentId: Fixture.intentId)
        }

        guard case .unsupportedType("SWAP") = error else {
            Issue.record("Expected .unsupportedType, got \(error)")
            return
        }
    }

    // MARK: - Report

    @Test
    func reportPostsHashToIntentTransactionByIdAsReceived() async throws {
        let requestRecorder = RequestRecorder()
        let sut = try Self.makeSUT(statusCode: 200, requestRecorder: requestRecorder)

        try await sut.reportTransaction(sendIntentID: Fixture.intentId.uppercased(), transactionHash: Fixture.transactionHash)

        let request = try #require(requestRecorder.requests.first)
        let body = try #require(request.httpBody)
        #expect(requestRecorder.requests.count == 1)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.path == "/api/transactions/v1/intents/\(Fixture.intentId.uppercased())/transaction")
        #expect(try JSONDecoder().decode([String: String].self, from: body) == ["txHash": Fixture.transactionHash])
    }

    @Test(arguments: [200, 201, 204])
    func reportSucceedsOnSuccessStatusCode(successStatusCode: Int) async throws {
        let sut = try Self.makeSUT(statusCode: successStatusCode)

        try await sut.reportTransaction(sendIntentID: Fixture.intentId, transactionHash: Fixture.transactionHash)
    }

    @Test(arguments: ["", "abc", "../intents"])
    func reportRejectsMalformedIdWithoutRequest(intentId: String) async throws {
        let requestRecorder = RequestRecorder()
        let sut = try Self.makeSUT(statusCode: 200, requestRecorder: requestRecorder)

        let error = try await #require(throws: SendMCPIntentError.self) {
            try await sut.reportTransaction(sendIntentID: intentId, transactionHash: Fixture.transactionHash)
        }

        guard case .invalidIntentId(intentId) = error else {
            Issue.record("Expected .invalidIntentId, got \(error)")
            return
        }
        #expect(requestRecorder.requests.isEmpty)
    }

    @Test(arguments: StatusCodes.error + [409, 410])
    func reportThrowsRequestFailedOnErrorStatusCode(errorStatusCode: Int) async throws {
        let sut = try Self.makeSUT(statusCode: errorStatusCode)

        let error = try await #require(throws: SendMCPIntentError.self) {
            try await sut.reportTransaction(sendIntentID: Fixture.intentId, transactionHash: Fixture.transactionHash)
        }

        guard case .requestFailed = error else {
            Issue.record("Expected .requestFailed, got \(error)")
            return
        }
    }
}

// MARK: - Factory methods

extension MoyaMCPSendIntentClientTests {
    private static func makeSUT(
        statusCode: Int,
        responseBody: String = "",
        requestRecorder: RequestRecorder = RequestRecorder(),
        sourceLocation: SourceLocation = #_sourceLocation
    ) throws -> MoyaMCPSendIntentClient {
        try makeSUT(
            sampleResponse: .networkResponse(statusCode, Data(responseBody.utf8)),
            requestRecorder: requestRecorder,
            sourceLocation: sourceLocation
        )
    }

    private static func makeSUT(
        networkError: some Error,
        sourceLocation: SourceLocation = #_sourceLocation
    ) throws -> MoyaMCPSendIntentClient {
        try makeSUT(
            sampleResponse: .networkError(networkError as NSError),
            requestRecorder: RequestRecorder(),
            sourceLocation: sourceLocation
        )
    }

    private static func makeSUT(
        sampleResponse: EndpointSampleResponse,
        requestRecorder: RequestRecorder,
        sourceLocation: SourceLocation
    ) throws -> MoyaMCPSendIntentClient {
        let provider = MoyaProvider<MCPTransactionIntentTarget>(
            endpointClosure: { target in
                let endpoint = Endpoint(
                    url: target.baseURL.appendingPathComponent(target.path).absoluteString,
                    sampleResponseClosure: { sampleResponse },
                    method: target.method,
                    task: target.task,
                    httpHeaderFields: target.headers
                )
                requestRecorder.record(endpoint)
                return endpoint
            },
            stubClosure: MoyaProvider.immediatelyStub
        )

        let anyBaseURL = try #require(URL(string: "https://example.com"), sourceLocation: sourceLocation)

        return MoyaMCPSendIntentClient(provider: provider, baseURL: anyBaseURL)
    }
}

// MARK: - Fixtures

extension MoyaMCPSendIntentClientTests {
    private enum StatusCodes {
        static let error = [400, 401, 403, 404, 429, 500, 503]
    }

    private enum Fixture {
        static let intentId = "3f7c2a1e-9b4d-4c6a-8e21-5d0f7a9b1c33"
        static let transactionHash = "0x5c504ed432cb51138bcf09aa5e8a410dd4a1e204ef84bfed1be16dfba1b22060"

        static func intentJSON(type: String) -> String {
            """
            {
              "intentId": "\(intentId)",
              "type": "\(type)",
              "status": "CREATED",
              "networkId": "ethereum",
              "fromAddress": "0xe34979ea46a0bb49f0e483f163c79be02101cd1b",
              "toAddress": "0x1111111111111111111111111111111111111111",
              "tokenId": "ethereum",
              "amount": "0.000001",
              "memo": null,
              "createdAt": "2026-10-14T12:40:51.387380Z",
              "sessionId": "6e838f6c-2117-4e74-9daf-82a584fdbeb1",
              "clientId": "https://claude.ai/oauth/claude-code-client-metadata"
            }
            """
        }
    }
}

private final class RequestRecorder: Sendable {
    private let state = OSAllocatedUnfairLock(initialState: [URLRequest]())

    var requests: [URLRequest] {
        state.withLock { $0 }
    }

    func record(_ endpoint: Endpoint) {
        guard let request = try? endpoint.urlRequest() else {
            return
        }

        state.withLock { $0.append(request) }
    }
}
