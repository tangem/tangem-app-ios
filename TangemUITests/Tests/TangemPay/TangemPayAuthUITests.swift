//
//  TangemPayAuthUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class TangemPayAuthUITests: BaseTestCase {
    func testExistingUserAuthorization_ShowsTangemPayTileOnMain() {
        setAllureId(9630)

        launchAndImportHotWallet()
            .verifyTangemPayTileExists()
    }
}
