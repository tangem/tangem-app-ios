//
//  CollectiblesVaultProgramTests.swift
//  TangemCollectiblesTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
import Foundation
import SolanaSwift
@testable import TangemCollectibles

/// Ground-truth fixtures come from the `tangem_gacha_vault` devnet deployment
/// (program `29agFEruMu2jedVwnDgKPuq7ejmTiB7sEqzdhufQQS9u`) and its integration doc.
@Suite("CollectiblesVaultProgram")
struct CollectiblesVaultProgramTests {
    // MARK: - Anchor discriminators

    @Test("Instruction discriminators follow the Anchor formula")
    func instructionDiscriminatorMatchesAnchorFormula() {
        #expect(CollectiblesVaultProgram.instructionDiscriminator("init_vault") == Data([77, 79, 85, 150, 33, 217, 52, 106]))
        #expect(CollectiblesVaultProgram.instructionDiscriminator("update_vault") == Data([67, 229, 185, 188, 226, 11, 210, 60]))
        #expect(CollectiblesVaultProgram.instructionDiscriminator("purchase_pack") == Data([43, 116, 135, 75, 251, 67, 81, 26]))
        #expect(CollectiblesVaultProgram.instructionDiscriminator("close_vault") == Data([141, 103, 17, 126, 72, 75, 29, 29]))
    }

    @Test("Account discriminators follow the Anchor formula")
    func accountDiscriminatorMatchesAnchorFormula() {
        #expect(CollectiblesVaultProgram.accountDiscriminator("Config") == Data([155, 12, 170, 224, 30, 250, 204, 130]))
        #expect(CollectiblesVaultProgram.accountDiscriminator("Vault") == Data([211, 8, 232, 43, 2, 152, 117, 119]))
    }

    // MARK: - Program id

    @Test("A malformed program id is rejected")
    func rejectsMalformedProgramId() {
        #expect(throws: (any Error).self) {
            try CollectiblesVaultProgram(programId: "not-a-base58-key")
        }
    }

    /// `PublicKey(string:)` checks only the character count, so both a long invalid-alphabet string
    /// (decodes to nothing) and a short-decoding valid one (fewer than 32 bytes) construct a key.
    @Test("A program id that decodes to the wrong length is rejected", arguments: [
        String(repeating: "l", count: 44),
        String(repeating: "z", count: 32),
    ])
    func rejectsProgramIdThatDecodesToWrongLength(programId: String) {
        #expect(throws: (any Error).self) {
            try CollectiblesVaultProgram(programId: programId)
        }
    }

    // MARK: - PDA derivation

    @Test("Derives the config PDA of the devnet program")
    func derivesConfigPDA() throws {
        let program = try CollectiblesVaultProgram(programId: CollectiblesVaultProgram.devnetProgramId)
        #expect(try program.configAddress() == "53EDbBLB1sQuVv6aH7us9TQ7XSGXFijPmPdAGNcY8Y1d")
    }

    @Test("Derives the vault PDA from the cold owner bytes")
    func derivesVaultPDAFromColdOwnerBytes() throws {
        let program = try CollectiblesVaultProgram(programId: CollectiblesVaultProgram.devnetProgramId)
        let coldOwner = try #require(PublicKey(string: "CfzgiAsor8k46oAr1zLybapCbAK44892DYxBJUerNX31"))
        #expect(try program.vaultAddress(coldOwner: coldOwner.data) == "aBRHcE97NY1MjVqGbc2LX2cApfPg9r5h5T1KNZS93oA")
    }

    @Test("Cold owner bytes of the wrong length are rejected")
    func rejectsColdOwnerBytesOfWrongLength() throws {
        let program = try CollectiblesVaultProgram(programId: CollectiblesVaultProgram.devnetProgramId)
        #expect(throws: (any Error).self) {
            try program.vaultAddress(coldOwner: Data(repeating: 0xAA, count: 31))
        }
    }

    @Test("Derives the vault USDC ATA for an off-curve owner")
    func derivesVaultUsdcATAForOffCurveOwner() throws {
        let vault = try #require(PublicKey(string: "aBRHcE97NY1MjVqGbc2LX2cApfPg9r5h5T1KNZS93oA"))
        let usdcMint = try #require(PublicKey(string: "Gh9ZwEmdLJ8DscKNTkTqPbNwLNNBjuSzaG9Vp2KGtKJr"))
        let vaultUsdc = try CollectiblesVaultProgram.associatedTokenAddress(owner: vault, mint: usdcMint)
        #expect(vaultUsdc.base58EncodedString == "6atEYZQxh5sYXjnwS5WfVvnh6p8wUXibc2xcD2Gftfqs")
    }

    /// For this owner the first ATA candidate (bump 255) is a SHA-256 digest with a
    /// leading zero byte, which the derivation must keep byte-exact — that zero byte
    /// is why the address's base58 form starts with `1`. Locks the derivation to the
    /// runtime's raw-digest behaviour.
    @Test("Keeps the leading zero byte of an ATA digest")
    func derivesVaultUsdcATAWithLeadingZeroByte() throws {
        let owner = try #require(PublicKey(string: "E5DyZRiE4b3mwWZjrdTEacX6vnYgUnkXB4pMZzRspw1S"))
        let usdcMint = try #require(PublicKey(string: "Gh9ZwEmdLJ8DscKNTkTqPbNwLNNBjuSzaG9Vp2KGtKJr"))
        let ata = try CollectiblesVaultProgram.associatedTokenAddress(owner: owner, mint: usdcMint)
        #expect(ata.base58EncodedString == "14p5BeF8hhXniU2ugEGz5unqf58C6ckZgXMrPvvnGgb3")
    }

    // MARK: - Vault USDC account

    @Test("Derives the vault USDC address from the cold owner bytes")
    func derivesVaultUsdcAddressFromColdOwnerBytes() throws {
        let program = try CollectiblesVaultProgram(programId: CollectiblesVaultProgram.devnetProgramId)
        let coldOwner = try #require(PublicKey(string: "CfzgiAsor8k46oAr1zLybapCbAK44892DYxBJUerNX31"))
        let usdcMint = try #require(PublicKey(string: "Gh9ZwEmdLJ8DscKNTkTqPbNwLNNBjuSzaG9Vp2KGtKJr"))

        let address = try program.vaultUsdcAddress(coldOwner: coldOwner.data, usdcMint: usdcMint.data)

        #expect(address == "6atEYZQxh5sYXjnwS5WfVvnh6p8wUXibc2xcD2Gftfqs")
    }

    @Test("Vault USDC address inputs of the wrong length are rejected", arguments: [
        (Data(repeating: 0xAA, count: 31), Data(repeating: 0xBB, count: 32)),
        (Data(repeating: 0xAA, count: 32), Data(repeating: 0xBB, count: 31)),
    ])
    func rejectsVaultUsdcAddressInputsOfWrongLength(coldOwner: Data, usdcMint: Data) throws {
        let program = try CollectiblesVaultProgram(programId: CollectiblesVaultProgram.devnetProgramId)

        #expect(throws: (any Error).self) {
            try program.vaultUsdcAddress(coldOwner: coldOwner, usdcMint: usdcMint)
        }
    }

    /// The associated token program's own account order, which is positional — a swapped pair still
    /// builds a valid-looking instruction that the program rejects on chain.
    @Test("Builds the idempotent vault USDC account instruction")
    func buildsIdempotentVaultUsdcInstruction() throws {
        let program = try CollectiblesVaultProgram(programId: CollectiblesVaultProgram.devnetProgramId)
        let coldOwner = try #require(PublicKey(string: "CfzgiAsor8k46oAr1zLybapCbAK44892DYxBJUerNX31"))
        let usdcMint = try #require(PublicKey(string: "Gh9ZwEmdLJ8DscKNTkTqPbNwLNNBjuSzaG9Vp2KGtKJr"))

        let instruction = try program.createVaultUsdcInstruction(
            payer: coldOwner.data,
            coldOwner: coldOwner.data,
            usdcMint: usdcMint.data
        )

        #expect(instruction.programId == "ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL")
        // `1` is CreateIdempotent; `0` — what every SDK builder emits — fails on an existing account
        #expect(instruction.data == Data([1]))
        #expect(instruction.accounts.map(\.address) == [
            "CfzgiAsor8k46oAr1zLybapCbAK44892DYxBJUerNX31",
            "6atEYZQxh5sYXjnwS5WfVvnh6p8wUXibc2xcD2Gftfqs",
            "aBRHcE97NY1MjVqGbc2LX2cApfPg9r5h5T1KNZS93oA",
            "Gh9ZwEmdLJ8DscKNTkTqPbNwLNNBjuSzaG9Vp2KGtKJr",
            "11111111111111111111111111111111",
            "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA",
        ])
        // Only the payer signs: the vault owns the account without authorising its creation, which is
        // what lets the instruction ride in a transaction the vault never signs
        #expect(instruction.accounts.map(\.isSigner) == [true, false, false, false, false, false])
        #expect(instruction.accounts.map(\.isWritable) == [true, true, false, false, false, false])
    }

    @Test("Vault USDC instruction inputs of the wrong length are rejected", arguments: [
        (payer: Data(count: 31), coldOwner: Data(count: 32), usdcMint: Data(count: 32)),
        (payer: Data(count: 32), coldOwner: Data(count: 31), usdcMint: Data(count: 32)),
        (payer: Data(count: 32), coldOwner: Data(count: 32), usdcMint: Data(count: 31)),
    ])
    func rejectsVaultUsdcInstructionInputsOfWrongLength(payer: Data, coldOwner: Data, usdcMint: Data) throws {
        let program = try CollectiblesVaultProgram(programId: CollectiblesVaultProgram.devnetProgramId)

        #expect(throws: (any Error).self) {
            try program.createVaultUsdcInstruction(payer: payer, coldOwner: coldOwner, usdcMint: usdcMint)
        }
    }

    // MARK: - Init vault instruction

    /// The program's account order: vault, cold owner (signer), payer (signer), system program.
    @Test("Builds the init_vault instruction")
    func buildsInitVaultInstruction() throws {
        let program = try CollectiblesVaultProgram(programId: CollectiblesVaultProgram.devnetProgramId)
        let coldOwner = try #require(PublicKey(string: "CfzgiAsor8k46oAr1zLybapCbAK44892DYxBJUerNX31"))
        let payer = try #require(PublicKey(string: "Gh9ZwEmdLJ8DscKNTkTqPbNwLNNBjuSzaG9Vp2KGtKJr"))

        let instruction = try program.initVaultInstruction(
            coldOwner: coldOwner.data,
            payer: payer.data,
            sessionKey: Data(repeating: 0xBB, count: 32),
            perSpinCap: 300_000_000,
            dailyCap: 900_000_000
        )

        #expect(instruction.programId == CollectiblesVaultProgram.devnetProgramId)
        #expect(instruction.accounts.map(\.address) == [
            "aBRHcE97NY1MjVqGbc2LX2cApfPg9r5h5T1KNZS93oA",
            "CfzgiAsor8k46oAr1zLybapCbAK44892DYxBJUerNX31",
            "Gh9ZwEmdLJ8DscKNTkTqPbNwLNNBjuSzaG9Vp2KGtKJr",
            "11111111111111111111111111111111",
        ])
        #expect(instruction.accounts.map(\.isSigner) == [false, true, true, false])
        #expect(instruction.accounts.map(\.isWritable) == [true, false, true, false])
        // Ties the builder to the encoder: a swapped perSpinCap/dailyCap, or a session key forwarded
        // where a cap belongs, would build valid accounts but wrong data and only fail here.
        #expect(instruction.data == (try CollectiblesVaultProgram.initVaultInstructionData(
            sessionKey: Data(repeating: 0xBB, count: 32),
            perSpinCap: 300_000_000,
            dailyCap: 900_000_000
        )))
    }

    @Test("An init_vault payer of the wrong length is rejected")
    func rejectsInitVaultInstructionPayerOfWrongLength() throws {
        let program = try CollectiblesVaultProgram(programId: CollectiblesVaultProgram.devnetProgramId)
        let coldOwner = try #require(PublicKey(string: "CfzgiAsor8k46oAr1zLybapCbAK44892DYxBJUerNX31"))

        #expect(throws: (any Error).self) {
            try program.initVaultInstruction(
                coldOwner: coldOwner.data,
                payer: Data(repeating: 0xAA, count: 31),
                sessionKey: Data(repeating: 0xBB, count: 32),
                perSpinCap: 1,
                dailyCap: 1
            )
        }
    }

    // MARK: - Update vault instruction

    /// Accounts: vault, cold owner (read-only signer). No payer — nothing is allocated by this instruction.
    /// Parameterized over a `nil` and a present session key: with both sides of the `sessionKey: nil` case
    /// nil, that half alone can't tell a builder that drops the key on its way to the encoder from one that
    /// forwards it correctly — the non-nil case, the actual rekey path, is what closes that gap.
    @Test("Builds the update_vault instruction", arguments: [nil, Data(repeating: 0xBB, count: 32)] as [Data?])
    func buildsUpdateVaultInstruction(sessionKey: Data?) throws {
        let program = try CollectiblesVaultProgram(programId: CollectiblesVaultProgram.devnetProgramId)
        let coldOwner = try #require(PublicKey(string: "CfzgiAsor8k46oAr1zLybapCbAK44892DYxBJUerNX31"))

        let instruction = try program.updateVaultInstruction(
            coldOwner: coldOwner.data,
            sessionKey: sessionKey,
            perSpinCap: 300_000_000,
            dailyCap: 900_000_000
        )

        #expect(instruction.programId == CollectiblesVaultProgram.devnetProgramId)
        #expect(instruction.accounts.map(\.address) == [
            "aBRHcE97NY1MjVqGbc2LX2cApfPg9r5h5T1KNZS93oA",
            "CfzgiAsor8k46oAr1zLybapCbAK44892DYxBJUerNX31",
        ])
        #expect(instruction.accounts.map(\.isSigner) == [false, true])
        #expect(instruction.accounts.map(\.isWritable) == [true, false])
        // Ties the builder to the encoder the same way `buildsInitVaultInstruction` does.
        #expect(instruction.data == (try CollectiblesVaultProgram.updateVaultInstructionData(
            sessionKey: sessionKey,
            perSpinCap: 300_000_000,
            dailyCap: 900_000_000
        )))
    }

    // MARK: - Purchase pack instruction

    @Test("Builds the purchase_pack instruction")
    func buildsPurchasePackInstruction() throws {
        let program = try CollectiblesVaultProgram(programId: CollectiblesVaultProgram.devnetProgramId)
        let coldOwner = try #require(PublicKey(string: "CfzgiAsor8k46oAr1zLybapCbAK44892DYxBJUerNX31"))
        let sessionKey = try #require(PublicKey(string: "E5DyZRiE4b3mwWZjrdTEacX6vnYgUnkXB4pMZzRspw1S"))

        let instruction = try program.purchasePackInstruction(
            coldOwner: coldOwner.data,
            sessionKey: sessionKey.data,
            config: try devnetConfig(of: program),
            amount: 25_000_000,
            feeAmount: 1_000_000,
            memo: "cc-1234:open"
        )

        #expect(instruction.programId == CollectiblesVaultProgram.devnetProgramId)
        #expect(instruction.accounts.map(\.address) == [
            "53EDbBLB1sQuVv6aH7us9TQ7XSGXFijPmPdAGNcY8Y1d",
            "aBRHcE97NY1MjVqGbc2LX2cApfPg9r5h5T1KNZS93oA",
            "E5DyZRiE4b3mwWZjrdTEacX6vnYgUnkXB4pMZzRspw1S",
            "Gh9ZwEmdLJ8DscKNTkTqPbNwLNNBjuSzaG9Vp2KGtKJr",
            "6atEYZQxh5sYXjnwS5WfVvnh6p8wUXibc2xcD2Gftfqs",
            "9ZSgA3PMjeAU8K6CWzgJ8oDnhZwwSgHZu6KP3X95t7Jq",
            "9qsWLjBgicHNncaM1qtLb4jqj4a4NixMwvNXNmsqQyV9",
            "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA",
        ])
        #expect(instruction.accounts.map(\.isSigner) == [false, false, true, false, false, false, false, false])
        #expect(instruction.accounts.map(\.isWritable) == [false, true, false, false, true, true, true, false])
        #expect(instruction.data == (try CollectiblesVaultProgram.purchasePackInstructionData(
            amount: 25_000_000,
            feeAmount: 1_000_000,
            memo: "cc-1234:open"
        )))
    }

    @Test("purchase_pack keys of the wrong length are rejected", arguments: [
        (coldOwner: 31, sessionKey: 32, usdcMint: 32, collectiblesUsdcAccount: 32, feeUsdcAccount: 32),
        (coldOwner: 32, sessionKey: 31, usdcMint: 32, collectiblesUsdcAccount: 32, feeUsdcAccount: 32),
        (coldOwner: 32, sessionKey: 32, usdcMint: 31, collectiblesUsdcAccount: 32, feeUsdcAccount: 32),
        (coldOwner: 32, sessionKey: 32, usdcMint: 32, collectiblesUsdcAccount: 31, feeUsdcAccount: 32),
        (coldOwner: 32, sessionKey: 32, usdcMint: 32, collectiblesUsdcAccount: 32, feeUsdcAccount: 31),
    ])
    func rejectsPurchasePackInstructionKeysOfWrongLength(
        coldOwner: Int,
        sessionKey: Int,
        usdcMint: Int,
        collectiblesUsdcAccount: Int,
        feeUsdcAccount: Int
    ) throws {
        let program = try CollectiblesVaultProgram(programId: CollectiblesVaultProgram.devnetProgramId)
        let config = CollectiblesConfigInfo(
            usdcMint: Data(count: usdcMint),
            collectiblesUsdcAccount: Data(count: collectiblesUsdcAccount),
            feeUsdcAccount: Data(count: feeUsdcAccount),
            minFeeBps: 100,
            maxFeeBps: 500
        )

        #expect(throws: (any Error).self) {
            try program.purchasePackInstruction(
                coldOwner: Data(count: coldOwner),
                sessionKey: Data(count: sessionKey),
                config: config,
                amount: 1,
                feeAmount: 0,
                memo: "cc"
            )
        }
    }

    // MARK: - Close vault instruction

    @Test("Builds the close_vault instruction")
    func buildsCloseVaultInstruction() throws {
        let program = try CollectiblesVaultProgram(programId: CollectiblesVaultProgram.devnetProgramId)
        let coldOwner = try #require(PublicKey(string: "CfzgiAsor8k46oAr1zLybapCbAK44892DYxBJUerNX31"))

        let instruction = try program.closeVaultInstruction(coldOwner: coldOwner.data)

        #expect(instruction.programId == CollectiblesVaultProgram.devnetProgramId)
        #expect(instruction.accounts.map(\.address) == [
            "aBRHcE97NY1MjVqGbc2LX2cApfPg9r5h5T1KNZS93oA",
            "CfzgiAsor8k46oAr1zLybapCbAK44892DYxBJUerNX31",
        ])
        #expect(instruction.accounts.map(\.isSigner) == [false, true])
        #expect(instruction.accounts.map(\.isWritable) == [true, true])
        #expect(instruction.data == CollectiblesVaultProgram.instructionDiscriminator("close_vault"))
    }

    @Test("A close_vault cold owner of the wrong length is rejected")
    func rejectsCloseVaultInstructionColdOwnerOfWrongLength() throws {
        let program = try CollectiblesVaultProgram(programId: CollectiblesVaultProgram.devnetProgramId)

        #expect(throws: (any Error).self) {
            try program.closeVaultInstruction(coldOwner: Data(count: 31))
        }
    }

    // MARK: - Config account

    /// Bytes fetched from the devnet config account `53EDbBLB1sQuVv6aH7us9TQ7XSGXFijPmPdAGNcY8Y1d`.
    private static let devnetConfigAccountData = Data(
        base64Encoded: "mwyq4B76zIKtbdnm3fQfKiZwulw19xJe+Y62TcL9MF5YyYuupu7XZOkoOVUJZf/U1krKr0bUXfcxjltPV8kMSH1gYl2Cm4N7hqQIUEd4g/rZZ93XJGmfY1Im7dYaVhpfB0GPFwNaf39/LRy7KpYTz3xzEH7Z5ZuyXLdQy82fbyK8F4zfpFdYmoNiez2h0gaidjS66O7bgD1GanQ/NMIfiiDM0v1mCX+YZAAAAQH/9AE="
    )!

    @Test("Parses the devnet config account")
    func parsesUsdcMintFromConfigAccount() throws {
        let program = try CollectiblesVaultProgram(programId: CollectiblesVaultProgram.devnetProgramId)

        let config = try program.configInfo(
            accountOwner: CollectiblesVaultProgram.devnetProgramId,
            accountData: Self.devnetConfigAccountData
        )
        let usdcMint = try #require(PublicKey(data: config.usdcMint))
        let collectiblesUsdcAccount = try #require(PublicKey(data: config.collectiblesUsdcAccount))
        let feeUsdcAccount = try #require(PublicKey(data: config.feeUsdcAccount))

        #expect(usdcMint.base58EncodedString == "Gh9ZwEmdLJ8DscKNTkTqPbNwLNNBjuSzaG9Vp2KGtKJr")
        #expect(collectiblesUsdcAccount.base58EncodedString == "9ZSgA3PMjeAU8K6CWzgJ8oDnhZwwSgHZu6KP3X95t7Jq")
        #expect(feeUsdcAccount.base58EncodedString == "9qsWLjBgicHNncaM1qtLb4jqj4a4NixMwvNXNmsqQyV9")
        // Same fixture, the fee-bps offsets (168/174, either side of the bump byte at 173) — pinned
        // against the real devnet account rather than only a self-built one that shares the same assumption.
        #expect(config.minFeeBps == 100)
        #expect(config.maxFeeBps == 500)
    }

    /// A config under another owner is the program not being where the app thinks it is, so it throws
    /// rather than reporting an absent one the way a missing vault does.
    @Test("A config owned by another program is rejected")
    func rejectsConfigOwnedByAnotherProgram() throws {
        let program = try CollectiblesVaultProgram(programId: CollectiblesVaultProgram.devnetProgramId)

        #expect(throws: (any Error).self) {
            try program.configInfo(
                accountOwner: "11111111111111111111111111111111",
                accountData: Self.devnetConfigAccountData
            )
        }
    }

    // MARK: - Vault account classification

    @Test("A data-less foreign account reads as no vault")
    func vaultInfoReadsNilForADataLessForeignAccount() throws {
        let program = try CollectiblesVaultProgram(programId: CollectiblesVaultProgram.devnetProgramId)
        let coldOwner = try #require(PublicKey(string: "CfzgiAsor8k46oAr1zLybapCbAK44892DYxBJUerNX31"))

        let info = try program.vaultInfo(
            coldOwner: coldOwner.data,
            accountOwner: "11111111111111111111111111111111",
            accountData: Data()
        )

        #expect(info == nil)
    }

    /// Allocating data at the PDA takes the PDA's signature, which only the program has — a data-bearing
    /// account under another owner can only be a lying RPC.
    @Test("A data-bearing foreign account is rejected")
    func vaultInfoRejectsADataBearingForeignAccount() throws {
        let program = try CollectiblesVaultProgram(programId: CollectiblesVaultProgram.devnetProgramId)
        let coldOwner = try #require(PublicKey(string: "CfzgiAsor8k46oAr1zLybapCbAK44892DYxBJUerNX31"))

        #expect(throws: (any Error).self) {
            try program.vaultInfo(
                coldOwner: coldOwner.data,
                accountOwner: "11111111111111111111111111111111",
                accountData: Data(repeating: 0, count: 8)
            )
        }
    }

    @Test("Parses a vault that matches its cold owner")
    func vaultInfoParsesAMatchingVault() throws {
        let program = try CollectiblesVaultProgram(programId: CollectiblesVaultProgram.devnetProgramId)
        let coldOwner = try #require(PublicKey(string: "CfzgiAsor8k46oAr1zLybapCbAK44892DYxBJUerNX31"))
        let sessionKey = Data(repeating: 0xBB, count: 32)

        var data = Data([211, 8, 232, 43, 2, 152, 117, 119])
        data += coldOwner.data + sessionKey
        data += u64LE(300_000_000) + u64LE(900_000_000) + u64LE(150_000_000) + i64LE(20_690)
        data += Data(repeating: 0, count: 8) // _reserved
        data += Data([0]) // live_buyback_mint = None
        data += Data([0]) // live_buyback_token = None
        data += Data([254]) // bump

        let info = try program.vaultInfo(
            coldOwner: coldOwner.data,
            accountOwner: CollectiblesVaultProgram.devnetProgramId,
            accountData: data
        )

        #expect(info?.vaultAddress == "aBRHcE97NY1MjVqGbc2LX2cApfPg9r5h5T1KNZS93oA")
        #expect(info?.sessionKey == sessionKey)
        #expect(info?.perSpinCap == 300_000_000)
        #expect(info?.dailyCap == 900_000_000)
        #expect(info?.spentToday == 150_000_000)
        #expect(info?.dayIndex == 20_690)
    }

    /// The PDA is a pure function of the cold owner; a vault whose stored `cold_owner` disagrees with the
    /// address it was read from can only be a wrong or forged account.
    @Test("A vault whose stored cold owner disagrees is rejected")
    func vaultInfoRejectsAVaultWhoseStoredColdOwnerDisagrees() throws {
        let program = try CollectiblesVaultProgram(programId: CollectiblesVaultProgram.devnetProgramId)
        let coldOwner = try #require(PublicKey(string: "CfzgiAsor8k46oAr1zLybapCbAK44892DYxBJUerNX31"))
        let anotherOwner = Data(repeating: 0xEE, count: 32)

        var data = Data([211, 8, 232, 43, 2, 152, 117, 119])
        data += anotherOwner + Data(repeating: 0xBB, count: 32)
        data += u64LE(1) + u64LE(2) + u64LE(3) + i64LE(4)
        data += Data(repeating: 0, count: 8)
        data += Data([0]) + Data([0]) + Data([254])

        #expect(throws: (any Error).self) {
            try program.vaultInfo(
                coldOwner: coldOwner.data,
                accountOwner: CollectiblesVaultProgram.devnetProgramId,
                accountData: data
            )
        }
    }

    // MARK: - Vault USDC balance

    @Test("Reads the vault USDC balance")
    func readsVaultUsdcBalance() throws {
        let program = try CollectiblesVaultProgram(programId: CollectiblesVaultProgram.devnetProgramId)
        let coldOwner = try #require(PublicKey(string: "CfzgiAsor8k46oAr1zLybapCbAK44892DYxBJUerNX31"))
        let usdcMint = try #require(PublicKey(string: "Gh9ZwEmdLJ8DscKNTkTqPbNwLNNBjuSzaG9Vp2KGtKJr"))
        let vault = try #require(PublicKey(string: "aBRHcE97NY1MjVqGbc2LX2cApfPg9r5h5T1KNZS93oA"))

        var data = usdcMint.data + vault.data
        data += Data(repeating: 0, count: 165 - data.count)
        data.replaceSubrange(64 ..< 72, with: u64LE(42_000_000))

        let balance = try program.vaultUsdcBalance(
            coldOwner: coldOwner.data,
            usdcMint: usdcMint.data,
            accountOwner: "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA",
            accountData: data
        )

        #expect(balance == 42_000_000)
    }

    @Test("A balance read with a cold owner of the wrong length is rejected")
    func rejectsVaultUsdcBalanceColdOwnerOfWrongLength() throws {
        let program = try CollectiblesVaultProgram(programId: CollectiblesVaultProgram.devnetProgramId)
        let usdcMint = try #require(PublicKey(string: "Gh9ZwEmdLJ8DscKNTkTqPbNwLNNBjuSzaG9Vp2KGtKJr"))

        #expect(throws: (any Error).self) {
            try program.vaultUsdcBalance(
                coldOwner: Data(count: 31),
                usdcMint: usdcMint.data,
                accountOwner: "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA",
                accountData: Data(count: 165)
            )
        }
    }

    @Test("A token account of another vault is rejected")
    func rejectsVaultUsdcBalanceForATokenAccountOwnedByAnotherVault() throws {
        let program = try CollectiblesVaultProgram(programId: CollectiblesVaultProgram.devnetProgramId)
        let coldOwner = try #require(PublicKey(string: "CfzgiAsor8k46oAr1zLybapCbAK44892DYxBJUerNX31"))
        let usdcMint = try #require(PublicKey(string: "Gh9ZwEmdLJ8DscKNTkTqPbNwLNNBjuSzaG9Vp2KGtKJr"))
        let anotherVault = Data(repeating: 0xEE, count: 32)

        var data = usdcMint.data + anotherVault
        data += Data(repeating: 0, count: 165 - data.count)

        #expect(throws: (any Error).self) {
            try program.vaultUsdcBalance(
                coldOwner: coldOwner.data,
                usdcMint: usdcMint.data,
                accountOwner: "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA",
                accountData: data
            )
        }
    }

    /// A wallet address passed where a token account belongs would otherwise read as a plausible-looking
    /// zero balance instead of the wrong-account mistake it actually is.
    @Test("A token account not owned by the token program is rejected")
    func rejectsVaultUsdcBalanceWhenTheAccountOwnerIsNotTheTokenProgram() throws {
        let program = try CollectiblesVaultProgram(programId: CollectiblesVaultProgram.devnetProgramId)
        let coldOwner = try #require(PublicKey(string: "CfzgiAsor8k46oAr1zLybapCbAK44892DYxBJUerNX31"))
        let usdcMint = try #require(PublicKey(string: "Gh9ZwEmdLJ8DscKNTkTqPbNwLNNBjuSzaG9Vp2KGtKJr"))
        let vault = try #require(PublicKey(string: "aBRHcE97NY1MjVqGbc2LX2cApfPg9r5h5T1KNZS93oA"))

        var data = usdcMint.data + vault.data
        data += Data(repeating: 0, count: 165 - data.count)

        #expect(throws: (any Error).self) {
            try program.vaultUsdcBalance(
                coldOwner: coldOwner.data,
                usdcMint: usdcMint.data,
                accountOwner: CollectiblesVaultProgram.devnetProgramId,
                accountData: data
            )
        }
    }

    @Test("Truncated token account data is rejected")
    func rejectsTruncatedVaultUsdcAccountData() throws {
        let program = try CollectiblesVaultProgram(programId: CollectiblesVaultProgram.devnetProgramId)
        let coldOwner = try #require(PublicKey(string: "CfzgiAsor8k46oAr1zLybapCbAK44892DYxBJUerNX31"))
        let usdcMint = try #require(PublicKey(string: "Gh9ZwEmdLJ8DscKNTkTqPbNwLNNBjuSzaG9Vp2KGtKJr"))
        let vault = try #require(PublicKey(string: "aBRHcE97NY1MjVqGbc2LX2cApfPg9r5h5T1KNZS93oA"))

        let data = usdcMint.data + vault.data // 64 bytes, short of the 165-byte token account layout

        #expect(throws: (any Error).self) {
            try program.vaultUsdcBalance(
                coldOwner: coldOwner.data,
                usdcMint: usdcMint.data,
                accountOwner: "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA",
                accountData: data
            )
        }
    }

    @Test("A token account of another mint is rejected")
    func rejectsVaultUsdcBalanceForATokenAccountOfAnotherMint() throws {
        let program = try CollectiblesVaultProgram(programId: CollectiblesVaultProgram.devnetProgramId)
        let coldOwner = try #require(PublicKey(string: "CfzgiAsor8k46oAr1zLybapCbAK44892DYxBJUerNX31"))
        let usdcMint = try #require(PublicKey(string: "Gh9ZwEmdLJ8DscKNTkTqPbNwLNNBjuSzaG9Vp2KGtKJr"))
        let vault = try #require(PublicKey(string: "aBRHcE97NY1MjVqGbc2LX2cApfPg9r5h5T1KNZS93oA"))
        let anotherMint = Data(repeating: 0xDD, count: 32)

        var data = anotherMint + vault.data
        data += Data(repeating: 0, count: 165 - data.count)

        #expect(throws: (any Error).self) {
            try program.vaultUsdcBalance(
                coldOwner: coldOwner.data,
                usdcMint: usdcMint.data,
                accountOwner: "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA",
                accountData: data
            )
        }
    }

    // MARK: - Borsh instruction data

    @Test("Encodes init_vault data")
    func encodesInitVaultInstructionData() throws {
        let sessionKey = Data(repeating: 0xBB, count: 32)
        let data = try CollectiblesVaultProgram.initVaultInstructionData(
            sessionKey: sessionKey,
            perSpinCap: 300_000_000,
            dailyCap: 900_000_000
        )

        // #require, not #expect: the slicing below traps on wrong-size data
        try #require(data.count == 8 + 32 + 8 + 8)
        #expect(data.prefix(8) == CollectiblesVaultProgram.instructionDiscriminator("init_vault"))
        #expect(data[8 ..< 40] == sessionKey)
        #expect(data[40 ..< 48] == Data([0, 163, 225, 17, 0, 0, 0, 0])) // 300_000_000 u64 LE
        #expect(data[48 ..< 56] == Data([0, 233, 164, 53, 0, 0, 0, 0])) // 900_000_000 u64 LE
    }

    @Test("An init_vault session key of the wrong length is rejected")
    func rejectsInitVaultSessionKeyOfWrongLength() {
        #expect(throws: (any Error).self) {
            try CollectiblesVaultProgram.initVaultInstructionData(
                sessionKey: Data(repeating: 0xBB, count: 31),
                perSpinCap: 1,
                dailyCap: 1
            )
        }
    }

    /// The program's `0 < per_spin_cap <= daily_cap` rule (error 6004), failed before the card tap.
    @Test("init_vault caps violating the program rule are rejected", arguments: [
        (perSpinCap: UInt64(0), dailyCap: UInt64(100)),
        (perSpinCap: UInt64(101), dailyCap: UInt64(100)),
    ])
    func rejectsInitVaultCapsViolatingTheProgramRule(perSpinCap: UInt64, dailyCap: UInt64) {
        #expect(throws: (any Error).self) {
            try CollectiblesVaultProgram.initVaultInstructionData(
                sessionKey: Data(repeating: 0xBB, count: 32),
                perSpinCap: perSpinCap,
                dailyCap: dailyCap
            )
        }
    }

    @Test("Encodes update_vault data with every field set")
    func encodesUpdateVaultInstructionDataWithAllFields() throws {
        let sessionKey = Data(repeating: 0xBB, count: 32)
        let data = try CollectiblesVaultProgram.updateVaultInstructionData(
            sessionKey: sessionKey,
            perSpinCap: 300_000_000,
            dailyCap: 900_000_000
        )

        let expected = CollectiblesVaultProgram.instructionDiscriminator("update_vault")
            + Data([1]) + sessionKey
            + Data([1]) + Data([0, 163, 225, 17, 0, 0, 0, 0])
            + Data([1]) + Data([0, 233, 164, 53, 0, 0, 0, 0])
        #expect(data == expected)
    }

    @Test("Encodes nil update_vault fields as Borsh None")
    func encodesUpdateVaultNilFieldsAsBorshNone() throws {
        let data = try CollectiblesVaultProgram.updateVaultInstructionData(
            sessionKey: nil,
            perSpinCap: nil,
            dailyCap: nil
        )

        #expect(data == CollectiblesVaultProgram.instructionDiscriminator("update_vault") + Data([0, 0, 0]))
    }

    @Test("update_vault caps violating the program rule are rejected")
    func rejectsUpdateVaultWhenBothCapsViolateTheProgramRule() {
        #expect(throws: (any Error).self) {
            try CollectiblesVaultProgram.updateVaultInstructionData(sessionKey: nil, perSpinCap: 101, dailyCap: 100)
        }
    }

    /// `per_spin_cap` must be positive standalone, even with the other cap left `nil` — the pair check
    /// above can't see a lone zero, so it needs its own rejection.
    @Test("A lone zero cap in update_vault is rejected", arguments: [
        (perSpinCap: UInt64?(0), dailyCap: UInt64?(nil)),
        (perSpinCap: UInt64?(nil), dailyCap: UInt64?(0)),
    ])
    func rejectsUpdateVaultWithALoneZeroCap(perSpinCap: UInt64?, dailyCap: UInt64?) {
        #expect(throws: (any Error).self) {
            try CollectiblesVaultProgram.updateVaultInstructionData(sessionKey: nil, perSpinCap: perSpinCap, dailyCap: dailyCap)
        }
    }

    /// A single cap is checked by the program against the *stored* value of the other,
    /// which the client cannot see here — so it must pass through unchecked.
    @Test("A single update_vault cap passes through unchecked")
    func encodesUpdateVaultWithSingleCapUnchecked() throws {
        let data = try CollectiblesVaultProgram.updateVaultInstructionData(sessionKey: nil, perSpinCap: 101, dailyCap: nil)

        let expected = CollectiblesVaultProgram.instructionDiscriminator("update_vault")
            + Data([0])
            + Data([1]) + Data([101, 0, 0, 0, 0, 0, 0, 0])
            + Data([0])
        #expect(data == expected)
    }

    @Test("An update_vault session key of the wrong length is rejected")
    func rejectsUpdateVaultSessionKeyOfWrongLength() {
        #expect(throws: (any Error).self) {
            try CollectiblesVaultProgram.updateVaultInstructionData(
                sessionKey: Data(repeating: 0xBB, count: 33),
                perSpinCap: nil,
                dailyCap: nil
            )
        }
    }

    @Test("Encodes purchase_pack data")
    func encodesPurchasePackInstructionData() throws {
        let data = try CollectiblesVaultProgram.purchasePackInstructionData(
            amount: 25_000_000,
            feeAmount: 1_000_000,
            memo: "cc-1234:open"
        )

        let expected = CollectiblesVaultProgram.instructionDiscriminator("purchase_pack")
            + Data([64, 120, 125, 1, 0, 0, 0, 0])
            + Data([64, 66, 15, 0, 0, 0, 0, 0])
            + Data([12, 0, 0, 0]) + Data("cc-1234:open".utf8)
        #expect(data == expected)
    }

    @Test("Encodes a purchase_pack memo of the maximum length")
    func encodesPurchasePackMemoOfTheMaximumLength() throws {
        let memo = String(repeating: "m", count: 256)

        let data = try CollectiblesVaultProgram.purchasePackInstructionData(amount: 1, feeAmount: 0, memo: memo)

        #expect(data.count == 8 + 8 + 8 + 4 + 256)
        #expect(data.suffix(256) == Data(memo.utf8))
    }

    @Test("Counts the purchase_pack memo length in bytes")
    func countsPurchasePackMemoLengthInBytes() throws {
        let fitting = String(repeating: "\u{E9}", count: 128)
        let overflowing = String(repeating: "\u{E9}", count: 129)

        let data = try CollectiblesVaultProgram.purchasePackInstructionData(amount: 1, feeAmount: 0, memo: fitting)

        #expect(data.suffix(256) == Data(fitting.utf8))
        #expect(throws: (any Error).self) {
            try CollectiblesVaultProgram.purchasePackInstructionData(amount: 1, feeAmount: 0, memo: overflowing)
        }
    }

    @Test("purchase_pack data the program would refuse is rejected", arguments: [
        (amount: UInt64(0), memo: "cc-1234:open"),
        (amount: UInt64(1), memo: ""),
        (amount: UInt64(1), memo: String(repeating: "m", count: 257)),
    ])
    func rejectsPurchasePackDataTheProgramWouldRefuse(amount: UInt64, memo: String) {
        #expect(throws: (any Error).self) {
            try CollectiblesVaultProgram.purchasePackInstructionData(amount: amount, feeAmount: 0, memo: memo)
        }
    }

    // MARK: - Config account parsing

    @Test("Parses a config account")
    func parsesConfigAccount() throws {
        let admin = Data(repeating: 0x11, count: 32)
        let usdcMint = Data(repeating: 0x22, count: 32)
        let collectiblesWallet = Data(repeating: 0x33, count: 32)
        let collectiblesUsdcAccount = Data(repeating: 0x44, count: 32)
        let feeUsdcAccount = Data(repeating: 0x55, count: 32)

        var data = Data([155, 12, 170, 224, 30, 250, 204, 130])
        data += admin + usdcMint + collectiblesWallet + collectiblesUsdcAccount + feeUsdcAccount
        data += Data([100, 0]) // min_fee_bps = 100, u16 LE
        data += Data([0]) // paused = false
        data += Data([1]) // _reserved: legacy filler, can legitimately be 1 — must be ignored
        data += Data([1]) // allow_buyback_delegation = true
        data += Data([250]) // bump
        data += Data([44, 1]) // max_fee_bps = 300, u16 LE

        let config = try CollectiblesVaultProgram.Config(data: data)

        #expect(config.admin == admin)
        #expect(config.usdcMint == usdcMint)
        #expect(config.collectiblesWallet == collectiblesWallet)
        #expect(config.collectiblesUsdcAccount == collectiblesUsdcAccount)
        #expect(config.feeUsdcAccount == feeUsdcAccount)
        #expect(config.minFeeBps == 100)
        #expect(config.maxFeeBps == 300)
        #expect(config.paused == false)
        #expect(config.allowBuybackDelegation == true)
        #expect(config.bump == 250)
    }

    @Test("A config account with the wrong discriminator is rejected")
    func rejectsConfigAccountWithWrongDiscriminator() {
        let data = Data(repeating: 0, count: 176)
        #expect(throws: (any Error).self) {
            try CollectiblesVaultProgram.Config(data: data)
        }
    }

    @Test("A truncated config account is rejected")
    func rejectsTruncatedConfigAccount() {
        // Correct discriminator but a short body — the fixed-layout reads past the
        // end must throw, not trap on a garbage RPC response
        let data = Data([155, 12, 170, 224, 30, 250, 204, 130]) + Data(repeating: 0, count: 92)

        #expect(throws: (any Error).self) {
            try CollectiblesVaultProgram.Config(data: data)
        }
    }

    /// Borsh booleans are strictly 0/1 and Anchor never writes anything else — another byte
    /// means misaligned or foreign data, not a truthy flag.
    @Test("A config account with a non-binary boolean byte is rejected")
    func rejectsConfigAccountWithNonBinaryBooleanByte() {
        var data = Data([155, 12, 170, 224, 30, 250, 204, 130])
        data += Data(repeating: 0x11, count: 32 * 5)
        data += Data([100, 0]) // fee_bps
        data += Data([2]) // paused — invalid boolean byte
        data += Data([0]) // _reserved
        data += Data([1]) // allow_buyback_delegation
        data += Data([250]) // bump
        data += Data([44, 1]) // max_fee_bps

        #expect(throws: (any Error).self) {
            try CollectiblesVaultProgram.Config(data: data)
        }
    }

    // MARK: - Vault account parsing

    @Test("Parses the vault tail with a cursor and ignores stale bytes")
    func parsesVaultTailWithCursorIgnoringStaleBytes() throws {
        let coldOwner = Data(repeating: 0xAA, count: 32)
        let sessionKey = Data(repeating: 0xBB, count: 32)

        var data = Data([211, 8, 232, 43, 2, 152, 117, 119])
        data += coldOwner + sessionKey
        data += u64LE(300_000_000) // per_spin_cap
        data += u64LE(900_000_000) // daily_cap
        data += u64LE(150_000_000) // spent_today
        data += i64LE(20_690) // day_index
        data += Data(repeating: 0xFF, count: 8) // _reserved, must be ignored
        data += Data([0]) // live_buyback_mint = None
        data += Data([0]) // live_buyback_token = None
        data += Data([254]) // bump
        // Unwritten tail keeps stale garbage from previous Some-states — a fixed-offset
        // reader would misread it as a live buyback (real devnet vault has 1 at byte 145)
        data += Data(repeating: 1, count: 179 - data.count)

        let vault = try CollectiblesVaultProgram.Vault(data: data)

        #expect(vault.coldOwner == coldOwner)
        #expect(vault.sessionKey == sessionKey)
        #expect(vault.perSpinCap == 300_000_000)
        #expect(vault.dailyCap == 900_000_000)
        #expect(vault.spentToday == 150_000_000)
        #expect(vault.dayIndex == 20_690)
        #expect(vault.liveBuybackMint == nil)
        #expect(vault.liveBuybackToken == nil)
        #expect(vault.bump == 254)
    }

    @Test("Parses a vault with live buyback slots")
    func parsesVaultWithLiveBuybackSlots() throws {
        let liveBuybackMint = Data(repeating: 0xCC, count: 32)
        let liveBuybackToken = Data(repeating: 0xDD, count: 32)

        var data = Data([211, 8, 232, 43, 2, 152, 117, 119])
        data += Data(repeating: 0xAA, count: 32) // cold_owner
        data += Data(repeating: 0xBB, count: 32) // session_key
        data += u64LE(1) + u64LE(2) + u64LE(3) + i64LE(4)
        data += Data(repeating: 0, count: 8) // _reserved
        data += Data([1]) + liveBuybackMint // live_buyback_mint = Some
        data += Data([1]) + liveBuybackToken // live_buyback_token = Some
        data += Data([7]) // bump
        data += Data(repeating: 0, count: 179 - data.count)

        let vault = try CollectiblesVaultProgram.Vault(data: data)

        #expect(vault.liveBuybackMint == liveBuybackMint)
        #expect(vault.liveBuybackToken == liveBuybackToken)
        #expect(vault.bump == 7)
    }

    @Test("A vault account with the wrong discriminator is rejected")
    func rejectsVaultAccountWithWrongDiscriminator() {
        let data = Data(repeating: 0, count: 179)
        #expect(throws: (any Error).self) {
            try CollectiblesVaultProgram.Vault(data: data)
        }
    }

    @Test("A truncated vault account is rejected")
    func rejectsTruncatedVaultAccount() {
        // Correct discriminator, cut mid-session_key
        let data = Data([211, 8, 232, 43, 2, 152, 117, 119]) + Data(repeating: 0xAA, count: 52)

        #expect(throws: (any Error).self) {
            try CollectiblesVaultProgram.Vault(data: data)
        }
    }

    @Test("A vault account truncated inside the buyback tail is rejected")
    func rejectsVaultAccountTruncatedInsideTheBuybackTail() {
        // The cursor-driven tail must bounds-check too: a Some tag with no pubkey behind it
        var data = Data([211, 8, 232, 43, 2, 152, 117, 119])
        data += Data(repeating: 0xAA, count: 32) // cold_owner
        data += Data(repeating: 0xBB, count: 32) // session_key
        data += u64LE(1) + u64LE(2) + u64LE(3) + i64LE(4)
        data += Data(repeating: 0, count: 8) // _reserved
        data += Data([1]) // live_buyback_mint = Some, pubkey missing

        #expect(throws: (any Error).self) {
            try CollectiblesVaultProgram.Vault(data: data)
        }
    }

    /// A Borsh option tag is strictly 0/1. Reading any other byte as `None` would advance the cursor
    /// one byte and let misaligned data still parse into a "valid" vault with garbage caps.
    @Test("A vault account with an unknown option tag is rejected")
    func rejectsVaultAccountWithUnknownOptionTag() {
        var data = Data([211, 8, 232, 43, 2, 152, 117, 119])
        data += Data(repeating: 0xAA, count: 32) // cold_owner
        data += Data(repeating: 0xBB, count: 32) // session_key
        data += u64LE(1) + u64LE(2) + u64LE(3) + i64LE(4)
        data += Data(repeating: 0, count: 8) // _reserved
        data += Data([7]) // live_buyback_mint — invalid option tag
        data += Data([0]) // live_buyback_token = None
        data += Data([254]) // bump

        #expect(throws: (any Error).self) {
            try CollectiblesVaultProgram.Vault(data: data)
        }
    }
}

// MARK: - Private implementation

private extension CollectiblesVaultProgramTests {
    func devnetConfig(of program: CollectiblesVaultProgram) throws -> CollectiblesConfigInfo {
        try program.configInfo(
            accountOwner: CollectiblesVaultProgram.devnetProgramId,
            accountData: Self.devnetConfigAccountData
        )
    }

    func u64LE(_ value: UInt64) -> Data {
        withUnsafeBytes(of: value.littleEndian) { Data($0) }
    }

    func i64LE(_ value: Int64) -> Data {
        withUnsafeBytes(of: value.littleEndian) { Data($0) }
    }
}
