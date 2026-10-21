//
//  SolanaComputeBudgetInstructionTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import BlockchainSdk

struct SolanaComputeBudgetInstructionTests {
    @Test
    func encodesLimitAndPrice() {
        let instructions = SolanaComputeBudgetInstruction.instructions(computeUnitLimit: 200_000, computeUnitPrice: 1_000_000)

        #expect(instructions.map(\.data) == [
            Data([0x02, 0x40, 0x0D, 0x03, 0x00]),
            Data([0x03, 0x40, 0x42, 0x0F, 0x00, 0x00, 0x00, 0x00, 0x00]),
        ])
        #expect(SolanaComputeBudgetInstruction.instructions(computeUnitLimit: nil, computeUnitPrice: nil).isEmpty)
    }

    @Test
    func decodesOnlySetComputeUnitLimit() {
        #expect(SolanaComputeBudgetInstruction.computeUnitLimit(fromData: [0x02, 0x40, 0x0D, 0x03, 0x00]) == 200_000)
        #expect(SolanaComputeBudgetInstruction.computeUnitLimit(fromData: [0x01, 0x00, 0x80, 0x00, 0x00]) == nil)
        #expect(SolanaComputeBudgetInstruction.computeUnitLimit(fromData: [0x03, 0x40, 0x42, 0x0F, 0x00, 0x00, 0x00, 0x00, 0x00]) == nil)
    }
}
