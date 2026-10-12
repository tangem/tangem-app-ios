//
//  DeprecationServiceTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
@testable import Tangem

@Suite("DeprecationService.isSystemDeprecated")
struct DeprecationServiceTests {
    @Test("Versions below the first supported one are deprecated", arguments: ["9.3", "16.4", "16.7.10", "17.0", "17.7.10"])
    func deprecated(systemVersion: String) {
        #expect(DeprecationService.isSystemDeprecated(systemVersion))
    }

    @Test("The first supported version and above are not deprecated", arguments: ["18.0", "18.0.1", "18.7.10", "26.0", "100.0"])
    func supported(systemVersion: String) {
        #expect(!DeprecationService.isSystemDeprecated(systemVersion))
    }
}
