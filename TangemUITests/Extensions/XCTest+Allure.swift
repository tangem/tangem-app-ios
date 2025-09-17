//
//  XCTest+Allure.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest

extension XCTest {
    func setAllureId(_ value: Int) {
        XCTContext.runActivity(named: "allure.id:\(value)") { _ in }
    }
    func setTestLayer(_ layer: String) {
        XCTContext.runActivity(named: "allure.layer:\(layer)") { _ in }
    }
}
