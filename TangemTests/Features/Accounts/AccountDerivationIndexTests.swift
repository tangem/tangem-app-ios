//
//  AccountDerivationIndexTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
@testable import Tangem

@Suite("Account derivation index")
struct AccountDerivationIndexTests {
    @Test("An index a derivation node can hold is taken as it is", arguments: [0, 1, 0x7FFF_FFFF])
    func indexInNodeRangeIsTaken(index: Int) throws {
        #expect(try AccountDerivationIndex.nodeIndex(index) == UInt32(index))
    }

    @Test("An index no derivation node can hold is rejected", arguments: [-1, Int(Int32.min), 0x8000_0000, Int(UInt32.max), Int(UInt32.max) + 1])
    func indexOutOfNodeRangeIsRejected(index: Int) {
        #expect(throws: (any Error).self) { try AccountDerivationIndex.nodeIndex(index) }
    }

    @Test("No joint account path is built for an index the backend counted below zero")
    func jointAccountPathRejectsNegativeIndex() {
        #expect(throws: (any Error).self) { try JointAccountKeyPath.derivationPath(forAccountAtIndex: -1) }
    }
}
