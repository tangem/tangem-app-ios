//
//  TangemAPIErrorMapperTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Testing
@testable import Tangem

@Suite("TangemAPIErrorMapper")
struct TangemAPIErrorMapperTests {
    @Test("A refusal keeps the reason the endpoint names it with beside its log text")
    func aRefusalKeepsItsReasonCode() throws {
        let body = #"{"statusCode":400,"error":"Bad Request","message":"The request has nonce 7. The Safe is at nonce 8","code":"NONCE_MISMATCH"}"#

        let error = try #require(Self.map(statusCode: 400, body: body))

        #expect(error.code == .badRequest)
        #expect(error.message == "The request has nonce 7. The Safe is at nonce 8")
        #expect(error.reasonCode == "NONCE_MISMATCH")
    }

    @Test("A failed validation names no reason")
    func aFailedValidationHasNoReasonCode() throws {
        let body = #"{"statusCode":400,"error":"Bad Request","message":["limit must not be greater than 100"]}"#

        let error = try #require(Self.map(statusCode: 400, body: body))

        #expect(error.code == .badRequest)
        #expect(error.message == "limit must not be greater than 100")
        #expect(error.reasonCode == nil)
    }

    @Test("A numeric code is not taken for a reason and costs the error nothing else")
    func aNumericCodeIsNotAReason() throws {
        let body = #"{"statusCode":409,"error":"Conflict","message":"The network is busy","code":42}"#

        let error = try #require(Self.map(statusCode: 409, body: body))

        #expect(error.code == .conflict)
        #expect(error.message == "The network is busy")
        #expect(error.reasonCode == nil)
    }
}

// MARK: - Private

private extension TangemAPIErrorMapperTests {
    static func map(statusCode: Int, body: String) -> TangemAPIError? {
        TangemAPIErrorMapper.map(response: Moya.Response(statusCode: statusCode, data: Data(body.utf8)))
    }
}
