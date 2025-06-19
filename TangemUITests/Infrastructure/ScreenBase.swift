//
//  ScreenBase.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest

class ScreenBase<T: UIElement>: Screen {
    let app: XCUIApplication

    init(_ app: XCUIApplication) {
        self.app = app
    }
}
