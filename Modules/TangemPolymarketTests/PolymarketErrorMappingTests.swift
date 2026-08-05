//
//  PolymarketErrorMappingTests.swift
//  TangemPolymarketTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import Moya
@testable import TangemPolymarket

@Suite("PolymarketAPIError mapping")
struct PolymarketErrorMappingTests {
    private let decoder = JSONDecoder()

    @Test("HTTP failure with an RFC-7807 body decodes ProblemDetail")
    func httpWithProblemDetail() {
        let body = Data("""
        { "type": "about:blank", "title": "Unprocessable", "status": 422, "detail": "bad cursor", "instance": "/events" }
        """.utf8)
        let moyaError = MoyaError.statusCode(Response(statusCode: 422, data: body))

        guard case .http(let statusCode, let problemDetail) = CommonPolymarketAPIService.mapMoyaError(moyaError, decoder: decoder) else {
            Issue.record("Expected .http")
            return
        }
        #expect(statusCode == 422)
        #expect(problemDetail?.title == "Unprocessable")
        #expect(problemDetail?.detail == "bad cursor")
        #expect(problemDetail?.status == 422)
    }

    @Test("HTTP failure with a non-JSON body maps to .http with no ProblemDetail")
    func httpWithoutProblemDetail() {
        let moyaError = MoyaError.statusCode(Response(statusCode: 500, data: Data("upstream exploded".utf8)))

        guard case .http(let statusCode, let problemDetail) = CommonPolymarketAPIService.mapMoyaError(moyaError, decoder: decoder) else {
            Issue.record("Expected .http")
            return
        }
        #expect(statusCode == 500)
        #expect(problemDetail == nil)
    }

    @Test("Transport failure with no response maps to .connection carrying the underlying error")
    func connectionError() {
        let urlError = URLError(.notConnectedToInternet)
        let moyaError = MoyaError.underlying(urlError, nil)

        guard case .connection(let underlying) = CommonPolymarketAPIService.mapMoyaError(moyaError, decoder: decoder) else {
            Issue.record("Expected .connection")
            return
        }
        #expect((underlying as? URLError)?.code == .notConnectedToInternet)
    }
}
