//
//  MetaplexTokenMetadataProgramTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SolanaSwift
import TangemSdk
import Testing
@testable import BlockchainSdk

struct MetaplexTokenMetadataProgramTests {
    private typealias Fixture = SolanaNFTFixtures.Programmable

    private let mint = PublicKey(string: Fixture.mint)!

    @Test
    func derivesTheAddressesOfTheDonorTransfer() throws {
        let ownerToken = try MetaplexTokenMetadataProgram.associatedTokenAddress(owner: PublicKey(string: Fixture.owner)!, mint: mint)
        let destinationToken = try MetaplexTokenMetadataProgram.associatedTokenAddress(
            owner: PublicKey(string: Fixture.destinationOwner)!,
            mint: mint
        )

        #expect(ownerToken.base58EncodedString == Fixture.ownerToken)
        #expect(destinationToken.base58EncodedString == Fixture.destinationToken)
        #expect(try MetaplexTokenMetadataProgram.metadataAddress(mint: mint).base58EncodedString == Fixture.metadata)
        #expect(try MetaplexTokenMetadataProgram.editionAddress(mint: mint).base58EncodedString == Fixture.edition)
        #expect(try MetaplexTokenMetadataProgram.tokenRecordAddress(mint: mint, token: ownerToken).base58EncodedString == Fixture.ownerTokenRecord)
        #expect(try MetaplexTokenMetadataProgram.tokenRecordAddress(mint: mint, token: destinationToken).base58EncodedString == Fixture.destinationTokenRecord)
    }

    @Test
    func readsTheTokenStandardAndRuleSetFromMainnetMetadata() throws {
        let metadata = try MetaplexTokenMetadataProgram.metadata(from: Fixture.metadataAccountData)

        #expect(metadata.tokenStandard == .programmableNonFungible)
        #expect(metadata.ruleSet?.base58EncodedString == Fixture.ruleSet)
        #expect(metadata.isProgrammable)
    }

    @Test(arguments: [
        (MetaplexTokenMetadataProgram.TokenStandard.nonFungible, false),
        (.nonFungibleEdition, false),
        (.programmableNonFungible, true),
        (.programmableNonFungibleEdition, true),
    ])
    func classifiesProgrammableStandards(standard: MetaplexTokenMetadataProgram.TokenStandard, isProgrammable: Bool) throws {
        let data = SolanaNFTMetadataBuilder(tokenStandard: standard.rawValue).build()

        #expect(try MetaplexTokenMetadataProgram.metadata(from: data).isProgrammable == isProgrammable)
    }

    @Test
    func treatsMetadataEndingBeforeTheTokenStandardAsNotProgrammable() throws {
        let data = SolanaNFTMetadataBuilder(tokenStandard: nil, truncatesAfterEditionNonce: true).build()

        let metadata = try MetaplexTokenMetadataProgram.metadata(from: data)

        #expect(metadata.tokenStandard == nil)
        #expect(!metadata.isProgrammable)
    }

    @Test
    func treatsACorruptedTokenStandardGroupAsNotProgrammable() throws {
        var data = SolanaNFTMetadataBuilder(tokenStandard: 4).build()
        data[SolanaNFTMetadataBuilder.tokenStandardOptionOffset] = 7

        let metadata = try MetaplexTokenMetadataProgram.metadata(from: data)

        #expect(metadata.tokenStandard == nil)
        #expect(!metadata.isProgrammable)
    }

    @Test
    func keepsTheTokenStandardWhenTheProgrammableConfigIsCorrupted() throws {
        var data = SolanaNFTMetadataBuilder(tokenStandard: 4).build()
        data[SolanaNFTMetadataBuilder.tokenStandardOptionOffset + 2 + 1 + 33 + 1 + 1] = 7

        let metadata = try MetaplexTokenMetadataProgram.metadata(from: data)

        #expect(metadata.tokenStandard == .programmableNonFungible)
        #expect(metadata.ruleSet == nil)
    }

    @Test
    func readsProgrammableMetadataWithoutRuleSet() throws {
        let data = SolanaNFTMetadataBuilder(tokenStandard: 4, ruleSet: nil).build()

        let metadata = try MetaplexTokenMetadataProgram.metadata(from: data)

        #expect(metadata.isProgrammable)
        #expect(metadata.ruleSet == nil)
    }

    @Test
    func rejectsAnAccountThatIsNotMetadata() {
        #expect(throws: MetaplexAccountError.unexpectedAccountKey) {
            try MetaplexTokenMetadataProgram.metadata(from: Fixture.unlockedTokenRecordData)
        }
    }

    @Test(arguments: [
        (UInt8(0), MetaplexTokenMetadataProgram.TokenState.unlocked),
        (1, .locked),
        (2, .listed),
    ])
    func readsTheTokenRecordState(rawState: UInt8, state: MetaplexTokenMetadataProgram.TokenState) throws {
        var data = Fixture.unlockedTokenRecordData
        data[2] = rawState

        #expect(try MetaplexTokenMetadataProgram.tokenRecordState(from: data) == state)
    }

    @Test
    func buildsTheDonorTransferInstruction() throws {
        let owner = PublicKey(string: Fixture.owner)!

        let instruction = try MetaplexTokenMetadataProgram.transferInstruction(
            mint: mint,
            owner: owner,
            destinationOwner: PublicKey(string: Fixture.destinationOwner)!,
            authority: owner,
            payer: owner,
            ruleSet: PublicKey(string: Fixture.ruleSet)!
        )

        #expect(instruction.programId == "metaqbxxUerdq28cj1RbAWkYQm3ybzjb6a8bt518x1s")
        #expect(instruction.data.hexString.lowercased() == Fixture.transferData)
        #expect(instruction.accounts.map(\.address) == [
            Fixture.ownerToken,
            Fixture.owner,
            Fixture.destinationToken,
            Fixture.destinationOwner,
            Fixture.mint,
            Fixture.metadata,
            Fixture.edition,
            Fixture.ownerTokenRecord,
            Fixture.destinationTokenRecord,
            Fixture.owner,
            Fixture.owner,
            "11111111111111111111111111111111",
            "Sysvar1nstructions1111111111111111111111111",
            "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA",
            "ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL",
            "auth9SigNpDKz4sJJ1DfCTuZrZNSAgh9sFD3rboVmgg",
            Fixture.ruleSet,
        ])
        #expect(instruction.accounts.map(\.isSigner) == (0 ..< 17).map { $0 == 9 || $0 == 10 })
        #expect(instruction.accounts.map(\.isWritable) == (0 ..< 17).map { [0, 2, 5, 7, 8, 10].contains($0) })
    }

    @Test
    func fillsTheRuleSetSlotsWithTheProgramIdWhenThereIsNoRuleSet() throws {
        let owner = PublicKey(string: Fixture.owner)!

        let instruction = try MetaplexTokenMetadataProgram.transferInstruction(
            mint: mint,
            owner: owner,
            destinationOwner: PublicKey(string: Fixture.destinationOwner)!,
            authority: owner,
            payer: owner,
            ruleSet: nil
        )

        #expect(instruction.accounts.suffix(2).map(\.address) == Array(repeating: "metaqbxxUerdq28cj1RbAWkYQm3ybzjb6a8bt518x1s", count: 2))
    }
}
