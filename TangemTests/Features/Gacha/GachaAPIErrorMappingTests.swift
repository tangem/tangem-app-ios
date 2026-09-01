//
//  GachaAPIErrorMappingTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import Moya
@testable import Tangem

@Suite("GachaAPIError mapping")
final class GachaAPIErrorMappingTests {
    @Test("HTTP failure keeps the status code and the raw body")
    func httpKeepsStatusAndBody() {
        let body = Data("machine out of stock".utf8)
        let moyaError = MoyaError.statusCode(Response(statusCode: 400, data: body))

        guard case .http(let statusCode, let receivedBody) = CommonGachaAPIService.mapMoyaError(moyaError) else {
            Issue.record("Expected .http")
            return
        }
        #expect(statusCode == 400)
        #expect(receivedBody == body)
    }

    @Test("Transport failure with no response maps to .connection carrying the underlying error")
    func connectionCarriesUnderlyingError() {
        let urlError = URLError(.notConnectedToInternet)
        let moyaError = MoyaError.underlying(urlError, nil)

        guard case .connection(let underlying) = CommonGachaAPIService.mapMoyaError(moyaError) else {
            Issue.record("Expected .connection")
            return
        }
        #expect((underlying as? URLError)?.code == .notConnectedToInternet)
    }
}
