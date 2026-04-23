//
//  SegWitLockingScriptBuilderTests.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemSdk
@testable import BlockchainSdk

class SegWitLockingScriptBuilderTests {
    @Test
    func fact0rn() throws {
        // given
        let builder = SegWitLockingScriptBuilder.fact0rn()

        // when
        let script = try builder.lockingScript(for: "fact1qhycckrkypu7ujkanlsrhjxq7avn6l7gumyv9n7")

        // then
        #expect(script.data == Data(hexString: "0014b9318b0ec40f3dc95bb3fc0779181eeb27aff91c"))
        #expect(script.type == .p2wpkh)
    }
}
