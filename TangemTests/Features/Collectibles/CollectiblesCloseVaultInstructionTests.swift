//
//  CollectiblesCloseVaultInstructionTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemCollectibles
@testable import Tangem

@Suite("CollectiblesVaultProgram.closeVaultInstruction")
struct CollectiblesCloseVaultInstructionTests {
    typealias SUT = CollectiblesVaultProgram

    @Test("Carries the discriminator the program answers to, and no arguments")
    func carriesDiscriminator() throws {
        let instruction = try makeSUT().closeVaultInstruction(coldOwner: Self.coldOwner)

        #expect(Array(instruction.data) == Self.closeVaultDiscriminator)
    }

    @Test("Passes the vault to close and the owner that signs for it")
    func passesAccounts() throws {
        let sut = try makeSUT()

        let instruction = try sut.closeVaultInstruction(coldOwner: Self.coldOwner)
        let vault = try #require(instruction.accounts.first)
        let owner = try #require(instruction.accounts.last)

        #expect(instruction.accounts.count == 2)
        #expect(vault.address == (try sut.vaultAddress(coldOwner: Self.coldOwner)))
        #expect(!vault.isSigner)
        #expect(vault.isWritable)
        #expect(owner.isSigner)
        // The rent of the closed vault lands on the owner, so its balance changes
        #expect(owner.isWritable)
    }

    @Test("Refuses an owner key of the wrong length")
    func refusesMalformedKey() {
        #expect(throws: (any Error).self) {
            try makeSUT().closeVaultInstruction(coldOwner: Data(repeating: 1, count: 31))
        }
    }
}

// MARK: - Helpers

private extension CollectiblesCloseVaultInstructionTests {
    /// Spelled out rather than hashed here: a rename of the instruction has to fail this test, not follow it.
    static let closeVaultDiscriminator: [UInt8] = [141, 103, 17, 126, 72, 75, 29, 29]

    static let coldOwner = Data(repeating: 1, count: 32)

    func makeSUT() throws -> SUT {
        try SUT(programId: SUT.devnetProgramId)
    }
}
