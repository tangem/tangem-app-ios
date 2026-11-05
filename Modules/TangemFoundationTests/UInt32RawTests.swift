//
//  UInt32RawTests.swift
//  TangemFoundationTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
import TangemFoundation

@Suite("UInt32 from a raw integer")
struct UInt32RawTests {
    @Test("A value UInt32 can hold converts as it is", arguments: [0, 1, Int(UInt32.max)])
    func valueInRangeConverts(value: Int) throws {
        #expect(try UInt32(raw: value) == UInt32(value))
    }

    @Test("A value UInt32 cannot hold is rejected", arguments: [-1, Int.min, Int(UInt32.max) + 1])
    func valueOutOfRangeIsRejected(value: Int) {
        #expect(throws: (any Error).self) { try UInt32(raw: value) }
    }
}
