//
//  CollectiblesProviderConfigurationTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemNetworkUtils
@testable import Tangem

@Suite("TangemProviderConfiguration.collectibles")
struct CollectiblesProviderConfigurationTests {
    @Test("Carries the app-wide session id the backend validates on every call")
    func carriesSessionId() {
        let headers = TangemProviderConfiguration.collectibles.headerValues

        #expect(headerValue(named: "session-id", in: headers) == AppConstants.sessionId)
    }
}

// MARK: - Helpers

private extension CollectiblesProviderConfigurationTests {
    func headerValue(named name: String, in headers: [APIHeaderKeyInfo]) -> String? {
        headers.first { $0.headerName == name }?.headerValue
    }
}
