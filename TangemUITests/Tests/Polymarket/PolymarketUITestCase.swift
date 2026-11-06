//
//  PolymarketUITestCase.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

class PolymarketUITestCase: BaseTestCase {
    override func setUp() {
        super.setUp()
        wireMockClient.resetRequestJournalSync()
    }
}
