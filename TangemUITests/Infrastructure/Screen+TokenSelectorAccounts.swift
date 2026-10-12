//
//  Screen+TokenSelectorAccounts.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

extension Screen {
    func assertTokenSelectorAccountVisible(_ accountName: String) {
        waitAndAssertTrue(
            tokenSelectorAccountHeader(accountName),
            "Account '\(accountName)' should be listed in the token selector"
        )
    }

    func assertTokenSelectorAccountNotVisible(_ accountName: String) {
        XCTAssertFalse(
            tokenSelectorAccountHeader(accountName).waitForExistence(timeout: .conditional),
            "Account '\(accountName)' should NOT be listed in the token selector"
        )
    }

    /// Type-agnostic: the header is an inline view when the section is flat and a card header when it is expandable.
    private func tokenSelectorAccountHeader(_ accountName: String) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(identifier: CommonUIAccessibilityIdentifiers.tokenSelectorAccountHeader(name: accountName))
            .firstMatch
    }
}
