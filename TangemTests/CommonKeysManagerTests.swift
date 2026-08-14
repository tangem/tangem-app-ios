//
//  CommonKeysManagerTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("CommonKeysManager")
struct CommonKeysManagerTests {
    @Test("The bundled config is parsed without an error")
    func parsesBundledConfig() throws {
        _ = try CommonKeysManager()
    }
}
