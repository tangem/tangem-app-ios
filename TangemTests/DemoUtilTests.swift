//
//  DemoUtilTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("DemoUtil")
struct DemoUtilTests {
    @Test("Every demo card ID has a valid format", arguments: DemoUtil().demoCardIds)
    func demoCardIdFormat(_ demoCardId: String) throws {
        let cardIdRegex = try NSRegularExpression(pattern: "[A-Z]{2}\\d{14}")
        let range = NSRange(location: 0, length: demoCardId.count)

        #expect(cardIdRegex.firstMatch(in: demoCardId, options: [], range: range) != nil)
    }
}
