//
//  PolymarketActivityFailureTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemPolymarket
@testable import Tangem

@Suite("Polymarket history failures")
struct PolymarketActivityFailureTests {
    @Test("Client errors are rejections that retrying will not fix", arguments: [400, 401, 403])
    func clientErrorsAreRejected(statusCode: Int) {
        let failure = PolymarketActivityFailure(error: PolymarketAPIError.http(statusCode: statusCode, problemDetail: nil))

        #expect(failure == .rejected(statusCode: statusCode))
        #expect(!failure.isRetriedAutomatically)
    }

    @Test("Server and connection errors are transient")
    func transientErrors() {
        #expect(PolymarketActivityFailure(error: PolymarketAPIError.http(statusCode: 503, problemDetail: nil)) == .transient)
        #expect(PolymarketActivityFailure(error: PolymarketAPIError.connection(underlying: URLError(.timedOut))) == .transient)
    }

    @Test("An unreadable answer is rejected")
    func decodingIsRejected() {
        let failure = PolymarketActivityFailure(error: PolymarketAPIError.decoding(field: "type", value: "?"))

        #expect(failure == .rejected(statusCode: nil))
    }
}
