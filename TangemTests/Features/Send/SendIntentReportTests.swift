//
//  SendIntentReportTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Testing
@testable import Tangem

@Suite("Send intent hash report")
struct SendIntentReportTests {
    @Test("A report that goes through on the first try isn't repeated")
    func reportsOnce() async throws {
        var attempts = 0
        var pauses: [Duration] = []

        try await SendIntentHandler.reportTransaction(
            report: { () async throws(MCPSendIntentError) in attempts += 1 },
            pause: { pauses.append($0) }
        )

        #expect(attempts == 1)
        #expect(pauses.isEmpty)
    }

    @Test("A temporary failure is retried after a growing pause")
    func retriesTemporaryFailures() async throws {
        var failures: [MCPSendIntentError] = [.timeout, Self.statusFailure(503)]
        var attempts = 0
        var pauses: [Duration] = []

        try await SendIntentHandler.reportTransaction(
            report: { () async throws(MCPSendIntentError) in
                attempts += 1
                if !failures.isEmpty {
                    throw failures.removeFirst()
                }
            },
            pause: { pauses.append($0) }
        )

        #expect(attempts == 3)
        #expect(pauses == [.seconds(2), .seconds(5)])
    }

    @Test("The report gives up after three retries")
    func givesUpAfterThreeRetries() async {
        var attempts = 0
        var pauses: [Duration] = []

        await #expect(throws: MCPSendIntentError.self) {
            try await SendIntentHandler.reportTransaction(
                report: { () async throws(MCPSendIntentError) in
                    attempts += 1
                    throw .noInternetConnection
                },
                pause: { pauses.append($0) }
            )
        }

        #expect(attempts == 4)
        #expect(pauses == [.seconds(2), .seconds(5), .seconds(15)])
    }

    @Test("A permanent failure isn't retried")
    func stopsOnPermanentFailure() async {
        var attempts = 0
        var pauses: [Duration] = []

        await #expect(throws: MCPSendIntentError.self) {
            try await SendIntentHandler.reportTransaction(
                report: { () async throws(MCPSendIntentError) in
                    attempts += 1
                    throw Self.statusFailure(404)
                },
                pause: { pauses.append($0) }
            )
        }

        #expect(attempts == 1)
        #expect(pauses.isEmpty)
    }

    @Test("A timeout, a missing connection, a network failure and a server-side status can be retried", arguments: [500, 502, 503, 401, 408, 429])
    func retriesTemporaryStatuses(statusCode: Int) {
        #expect(SendIntentHandler.canRetryReport(after: Self.statusFailure(statusCode)))
        #expect(SendIntentHandler.canRetryReport(after: .timeout))
        #expect(SendIntentHandler.canRetryReport(after: .noInternetConnection))
        #expect(SendIntentHandler.canRetryReport(after: .requestFailed(underlying: MoyaError.underlying(URLError(.cannotFindHost), nil))))
    }

    @Test("A rejected report can't be retried", arguments: [400, 403, 404, 409, 410])
    func doesNotRetryRejectedReports(statusCode: Int) {
        #expect(!SendIntentHandler.canRetryReport(after: Self.statusFailure(statusCode)))
        #expect(!SendIntentHandler.canRetryReport(after: .invalidIntentId("abc")))
    }

    private static func statusFailure(_ statusCode: Int) -> MCPSendIntentError {
        .requestFailed(underlying: MoyaError.statusCode(Response(statusCode: statusCode, data: Data())))
    }
}
