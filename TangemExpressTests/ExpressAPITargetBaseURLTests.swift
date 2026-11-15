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
    @Test("Every API type points at its own backend host under the requested API version", arguments: ExpressAPITarget.APIVersion.allCases)
    func baseURLPerAPIType(apiVersion: ExpressAPITarget.APIVersion) throws {
        for apiType in ExpressAPIType.allCases {
            let host = try #require(Constants.expectedHosts[apiType], "No expected host for \(apiType)")
            let target = ExpressAPITarget(expressAPIType: apiType, target: .providers, apiVersion: apiVersion)

            #expect(target.baseURL.absoluteString == "\(host)/\(apiVersion.rawValue)/", "Unexpected base URL for \(apiType)")
        }
    }
}

private extension ExpressAPITargetBaseURLTests {
    enum Constants {
        static let expectedHosts: [ExpressAPIType: String] = [
            .develop: "https://express.tangem.org",
            .developNew: "https://express-dev1.tests-d.com",
            .develop2: "https://express2.tests-d.com",
            .develop2New: "https://express-dev2.tests-d.com",
            .develop3: "https://express3.tests-d.com",
            .develop3New: "https://express-dev3.tests-d.com",
            .production: "https://express.tangem.com",
            .productionNew: "https://express-new.tangem.com",
            .stage: "https://express-stage.tangem.com",
            .develop4New: "https://express-dev4.tests-d.com",
            .stage2: "https://express.tests-s1.com",
            .develop5New: "https://express-dev5.tests-d.com",
            .stage3: "https://express.tests-s2.com",
            .develop6New: "https://express-dev6.tests-d.com",
            .mock: "\(WireMockEnvironment.baseURL)",
        ]
    }
}
