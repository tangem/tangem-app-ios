//
//  EarnDTOListRequestTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation
import Testing
@testable import Tangem

@Suite("EarnDTO.List.Request Tests")
struct EarnDTOListRequestTests {
    @Test("Sends the gross APY type as apyType=gross")
    func sendsGrossApyType() {
        let request = Self.makeRequest(apyType: .gross)

        #expect(request.parameters["apyType"] as? String == "gross")
    }

    @Test("Omits apyType when none is set")
    func omitsApyTypeWhenNotSet() {
        let request = Self.makeRequest(apyType: nil)

        #expect(request.parameters.keys.contains("apyType") == false)
    }

    @Test("Keeps the remaining parameters intact")
    func keepsRemainingParametersIntact() {
        let parameters = Self.makeRequest(apyType: .gross).parameters

        #expect(parameters["isForEarn"] as? String == "false")
        #expect(parameters["page"] as? Int == 2)
        #expect(parameters["limit"] as? Int == 20)
        #expect(parameters["type"] as? String == "yield")
        #expect(parameters["networkIds"] as? String == "ethereum,polygon-pos")
    }
}

private extension EarnDTOListRequestTests {
    static func makeRequest(apyType: EarnDTO.List.ApyType?) -> EarnDTO.List.Request {
        EarnDTO.List.Request(
            isForEarn: false,
            page: 2,
            limit: 20,
            type: .yield,
            networkIds: ["ethereum", "polygon-pos"],
            apyType: apyType
        )
    }
}
