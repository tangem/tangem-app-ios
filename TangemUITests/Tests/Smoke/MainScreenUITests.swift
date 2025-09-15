//
//  MainScreenUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest

final class MainScreenUITests: BaseTestCase {
    let token = "Polygon"

    func testHideToken_TokenNotDispayedOnMain() {
        setAllureId(880)
        launchApp(tangemApiType: .mock)

        let mainScreen = StoriesScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(token)
            .hideToken(name: token)

        mainScreen.validateTokenNotExists(token)
    }
}
