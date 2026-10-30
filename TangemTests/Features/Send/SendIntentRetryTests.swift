//
//  SendIntentRetryTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Testing
@testable import Tangem

@Suite("Send intent retry")
struct SendIntentRetryTests {
    @Test("A timeout or a missing connection can be retried")
    func retriesTimeoutAndMissingConnection() {
        #expect(SendIntentHandler.canRetryLoading(after: MCPSendIntentError.timeout))
        #expect(SendIntentHandler.canRetryLoading(after: MCPSendIntentError.noInternetConnection))
    }

    @Test("An error status can't be retried", arguments: [400, 401, 404, 409, 410, 500, 502, 503])
    func doesNotRetryErrorStatuses(statusCode: Int) {
        let error = MoyaError.statusCode(Response(statusCode: statusCode, data: Data()))

        #expect(!SendIntentHandler.canRetryLoading(after: .requestFailed(underlying: error)))
    }

    @Test("Another network failure can't be retried")
    func doesNotRetryOtherNetworkFailures() {
        let error = MoyaError.underlying(URLError(.cannotFindHost), nil)

        #expect(!SendIntentHandler.canRetryLoading(after: .requestFailed(underlying: error)))
    }

    @Test("A malformed or unsupported intent can't be retried")
    func doesNotRetryBadIntents() {
        #expect(!SendIntentHandler.canRetryLoading(after: MCPSendIntentError.invalidAmount("-1")))
        #expect(!SendIntentHandler.canRetryLoading(after: MCPSendIntentError.unsupportedType("SWAP")))
        #expect(!SendIntentHandler.canRetryLoading(after: MCPSendIntentError.invalidIntentId("abc")))
        #expect(!SendIntentHandler.canRetryLoading(after: .requestFailed(underlying: DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "")))))
    }
}
