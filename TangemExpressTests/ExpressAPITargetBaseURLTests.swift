//
//  ExpressAPITargetBaseURLTests.swift
//  TangemExpressTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemNetworkUtils
@testable import TangemExpress

@Suite("ExpressAPITarget base URL per API type")
struct ExpressAPITargetBaseURLTests {
    @Test("Every API type points at its own backend host")
    func baseURLPerAPIType() throws {
        for apiType in ExpressAPIType.allCases {
            let expected = try #require(Constants.expectedBaseURLs[apiType], "No expected base URL for \(apiType)")
            let target = ExpressAPITarget(expressAPIType: apiType, target: .providers)

            #expect(target.baseURL.absoluteString == expected, "Unexpected base URL for \(apiType)")
        }
    }
}

private extension ExpressAPITargetBaseURLTests {
    enum Constants {
        static let expectedBaseURLs: [ExpressAPIType: String] = [
            .develop: "https://express.tangem.org/v1/",
            .developNew: "https://express-dev1.tests-d.com/v1/",
            .develop2: "https://express2.tests-d.com/v1/",
            .develop2New: "https://express-dev2.tests-d.com/v1/",
            .develop3: "https://express3.tests-d.com/v1/",
            .develop3New: "https://express-dev3.tests-d.com/v1/",
            .production: "https://express.tangem.com/v1/",
            .productionNew: "https://express-new.tangem.com/v1/",
            .stage: "https://express-stage.tangem.com/v1/",
            .develop4New: "https://express-dev4.tests-d.com/v1/",
            .stage2: "https://express.tests-s1.com/v1/",
            .develop5New: "https://express-dev5.tests-d.com/v1/",
            .stage3: "https://express.tests-s2.com/v1/",
            .develop6New: "https://express-dev6.tests-d.com/v1/",
            .mock: "\(WireMockEnvironment.baseURL)/v1/",
        ]
    }
}
