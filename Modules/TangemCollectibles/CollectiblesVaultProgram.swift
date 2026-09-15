//
//  CollectiblesVaultProgram.swift
//  TangemCollectibles
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public import Foundation
import CryptoKit
import SolanaSwift

/// Byte-level layer of the `tangem_gacha_vault` Anchor program: discriminators, borsh-encoded instruction
/// data, PDA derivations and on-chain account parsing. Only what the app consumes today is public;
/// the rest widens member by member as the onboarding ceremony and the RPC vault reader land.
public struct CollectiblesVaultProgram {
    public enum ProgramError: Error {
        case invalidProgramId
        case invalidPublicKey
        case invalidAccountData
        case invalidCaps
        case impossibleVaultAccount
    }

    public static let devnetProgramId = "29agFEruMu2jedVwnDgKPuq7ejmTiB7sEqzdhufQQS9u"

    let programId: PublicKey

    public init(programId: String) throws {
        guard let programId = PublicKey(string: programId), programId.data.count == PublicKey.LENGTH else {
            throw ProgramError.invalidProgramId
        }

        self.programId = programId
    }

    // MARK: - Anchor discriminators

    static func instructionDiscriminator(_ name: String) -> Data {
        Data(SHA256.hash(data: Data(("global:" + name).utf8)).prefix(8))
    }

    static func accountDiscriminator(_ name: String) -> Data {
        Data(SHA256.hash(data: Data(("account:" + name).utf8)).prefix(8))
    }

    // MARK: - Addresses

    /// Base58 address of the program's singleton config PDA.
    func configAddress() throws -> String {
        try configPDA().base58EncodedString
    }

    /// Base58 address of the vault PDA for a cold owner's raw 32-byte public key.
    public func vaultAddress(coldOwner: Data) throws -> String {
        // SolanaSwift's `PublicKey(data:)` accepts anything up to 32 bytes, so a
        // truncated key would silently derive a PDA for the wrong owner
        guard coldOwner.count == PublicKey.LENGTH, let coldOwner = PublicKey(data: coldOwner) else {
            throw ProgramError.invalidPublicKey
        }

        return try vaultPDA(coldOwner: coldOwner).base58EncodedString
    }

    func configPDA() throws -> PublicKey {
        try PublicKey.findProgramAddress(
            seeds: [Data("config".utf8)],
            programId: programId
        ).get().0
    }

    func vaultPDA(coldOwner: PublicKey) throws -> PublicKey {
        try PublicKey.findProgramAddress(
            seeds: [Data("vault".utf8), coldOwner.data],
            programId: programId
        ).get().0
    }

    static func associatedTokenAddress(owner: PublicKey, mint: PublicKey) throws -> PublicKey {
        try PublicKey.associatedTokenAddress(
            walletAddress: owner,
            tokenMintAddress: mint,
            tokenProgramId: .tokenProgramId
        ).get()
    }

    // MARK: - Vault account classification

    /// Classifies the account fetched from the cold owner's vault PDA per the `CollectiblesVaultReader`
    /// contract: `nil` for "no vault" — which includes a data-less foreign account, the stray transfer
    /// `init_vault` handles — and a throw for data that should parse but does not.
    public func vaultInfo(coldOwner: Data, accountOwner: String, accountData: Data) throws -> CollectiblesVaultInfo? {
        let vaultAddress = try vaultAddress(coldOwner: coldOwner)

        guard accountOwner == programId.base58EncodedString else {
            // Allocating data at the PDA takes the PDA's signature, which only the program has —
            // a data-bearing account under another owner can only be a lying RPC
            guard accountData.isEmpty else {
                throw ProgramError.impossibleVaultAccount
            }

            return nil
        }

        let vault = try Vault(data: accountData)

        // The PDA is a pure function of the cold owner; a different one inside is a wrong or forged account
        guard vault.coldOwner == coldOwner else {
            throw ProgramError.impossibleVaultAccount
        }

        return CollectiblesVaultInfo(
            vaultAddress: vaultAddress,
            hotDelegate: vault.hotDelegate,
            perSpinCap: vault.perSpinCap,
            dailyCap: vault.dailyCap,
            spentToday: vault.spentToday,
            dayIndex: vault.dayIndex
        )
    }

    // MARK: - Instructions

    /// The program's account order: vault, cold owner (read-only signer), payer (writable signer), system
    /// program. When the cold owner pays for itself the two signer slots collapse into one account whose
    /// flags merge, which is exactly what the message compiler produces.
    public func initVaultInstruction(
        coldOwner: Data,
        payer: Data,
        hotDelegate: Data,
        perSpinCap: UInt64,
        dailyCap: UInt64
    ) throws -> CollectiblesInstruction {
        guard
            coldOwner.count == PublicKey.LENGTH, let coldOwnerKey = PublicKey(data: coldOwner),
            payer.count == PublicKey.LENGTH, let payerKey = PublicKey(data: payer)
        else {
            throw ProgramError.invalidPublicKey
        }

        let data = try Self.initVaultInstructionData(
            hotDelegate: hotDelegate,
            perSpinCap: perSpinCap,
            dailyCap: dailyCap
        )

        // Anchor's account-creation instructions require the System Program in the account list — a
        // different program from `programId` above, which is the vault program this instruction targets.
        let systemProgramAddress = PublicKey.programId.base58EncodedString

        return CollectiblesInstruction(
            programId: programId.base58EncodedString,
            accounts: [
                .init(address: try vaultPDA(coldOwner: coldOwnerKey).base58EncodedString, isSigner: false, isWritable: true),
                .init(address: coldOwnerKey.base58EncodedString, isSigner: true, isWritable: false),
                .init(address: payerKey.base58EncodedString, isSigner: true, isWritable: true),
                .init(address: systemProgramAddress, isSigner: false, isWritable: false),
            ],
            data: data
        )
    }

    // MARK: - Instruction data

    static func openPackInstructionData(amount: UInt64, memo: String) -> Data {
        var data = instructionDiscriminator("open_pack")
        data.appendLittleEndian(amount)
        data.appendBorshString(memo)
        return data
    }

    static func initVaultInstructionData(hotDelegate: Data, perSpinCap: UInt64, dailyCap: UInt64) throws -> Data {
        guard hotDelegate.count == PublicKey.LENGTH else {
            throw ProgramError.invalidPublicKey
        }

        try validateCaps(perSpinCap: perSpinCap, dailyCap: dailyCap)

        var data = instructionDiscriminator("init_vault")
        data.append(hotDelegate)
        data.appendLittleEndian(perSpinCap)
        data.appendLittleEndian(dailyCap)
        return data
    }

    /// Rotates the hot delegate and/or the caps; `nil` leaves a field as the chain holds it.
    /// - Warning: The program checks `0 < per_spin_cap <= daily_cap` against the *combined* state, so one cap
    /// alone can fail with `6004` because of the value already stored for the other.
    static func updateVaultInstructionData(
        hotDelegate: Data?,
        perSpinCap: UInt64?,
        dailyCap: UInt64?
    ) throws -> Data {
        // Borsh reads a `Pubkey` as fixed 32 bytes — a shorter one shifts every following field
        // and hands the vault to a delegate nobody holds
        if let hotDelegate, hotDelegate.count != PublicKey.LENGTH {
            throw ProgramError.invalidPublicKey
        }

        if let perSpinCap, let dailyCap {
            try validateCaps(perSpinCap: perSpinCap, dailyCap: dailyCap)
        }

        var data = instructionDiscriminator("update_vault")
        data.appendBorshOption(hotDelegate)
        data.appendBorshOption(perSpinCap)
        data.appendBorshOption(dailyCap)

        return data
    }

    /// The program's `0 < per_spin_cap <= daily_cap` rule (error `6004`), checked before the card tap.
    private static func validateCaps(perSpinCap: UInt64, dailyCap: UInt64) throws {
        guard perSpinCap > 0, perSpinCap <= dailyCap else {
            throw ProgramError.invalidCaps
        }
    }
}

// MARK: - Account state

extension CollectiblesVaultProgram {
    struct Config {
        let admin: Data
        let usdcMint: Data
        let collectiblesWallet: Data
        let collectiblesUsdcAccount: Data
        let feeUsdcAccount: Data
        let feeBps: UInt16
        let paused: Bool
        let allowBuybackDelegation: Bool
        let bump: UInt8
    }

    struct Vault {
        let coldOwner: Data
        let hotDelegate: Data
        let perSpinCap: UInt64
        let dailyCap: UInt64
        let spentToday: UInt64
        let dayIndex: Int64
        let liveBuybackMint: Data?
        let liveBuybackToken: Data?
        let bump: UInt8
    }
}

extension CollectiblesVaultProgram.Config {
    /// Fixed 174-byte layout — every field has a stable offset.
    /// Byte 171 is a legacy `_reserved` filler that can legitimately hold garbage.
    init(data: Data) throws {
        let reader = CollectiblesAccountReader(data: data)
        try reader.requireDiscriminator(CollectiblesVaultProgram.accountDiscriminator("Config"))
        try reader.requireCount(174)

        admin = try reader.bytes(at: 8, count: 32)
        usdcMint = try reader.bytes(at: 40, count: 32)
        collectiblesWallet = try reader.bytes(at: 72, count: 32)
        collectiblesUsdcAccount = try reader.bytes(at: 104, count: 32)
        feeUsdcAccount = try reader.bytes(at: 136, count: 32)
        feeBps = try reader.uint16LE(at: 168)
        paused = try reader.bool(at: 170)
        allowBuybackDelegation = try reader.bool(at: 172)
        bump = try reader.byte(at: 173)
    }
}

extension CollectiblesVaultProgram.Vault {
    /// Offsets are fixed only up to byte 112; the `Option<Pubkey>` tail is variable-width and keeps
    /// stale bytes from previous states, so it MUST be read with a cursor, never fixed offsets.
    init(data: Data) throws {
        let reader = CollectiblesAccountReader(data: data)
        try reader.requireDiscriminator(CollectiblesVaultProgram.accountDiscriminator("Vault"))

        coldOwner = try reader.bytes(at: 8, count: 32)
        hotDelegate = try reader.bytes(at: 40, count: 32)
        perSpinCap = try reader.uint64LE(at: 72)
        dailyCap = try reader.uint64LE(at: 80)
        spentToday = try reader.uint64LE(at: 88)
        dayIndex = try Int64(bitPattern: reader.uint64LE(at: 96))
        // 104..<112 is a reserved u64, ignored

        var cursor = 112
        liveBuybackMint = try Self.readOptionalPubkey(reader: reader, cursor: &cursor)
        liveBuybackToken = try Self.readOptionalPubkey(reader: reader, cursor: &cursor)
        bump = try reader.byte(at: cursor)
    }

    private static func readOptionalPubkey(reader: CollectiblesAccountReader, cursor: inout Int) throws -> Data? {
        switch try reader.byte(at: cursor) {
        case 0:
            cursor += 1
            return nil
        case 1:
            let value = try reader.bytes(at: cursor + 1, count: 32)
            cursor += 33
            return value
        default:
            throw CollectiblesVaultProgram.ProgramError.invalidAccountData
        }
    }
}

// MARK: - Spending math

public extension CollectiblesVaultProgram {
    /// Limit checks mirror the program exactly: fee in 128-bit intermediate math,
    /// lazy UTC day bucket, clamp-to-zero remainder.
    enum SpendingMath {
        private static let bpsScale: UInt64 = 10_000
        private static let secondsPerDay: TimeInterval = 86_400

        /// `floor(amount * feeBps / 10_000)` with a 128-bit intermediate product. A `feeBps` beyond the
        /// 10_000 scale would overflow the 64-bit quotient, so it saturates and `fitsCaps` rejects.
        static func fee(amount: UInt64, feeBps: UInt16) -> UInt64 {
            let product = amount.multipliedFullWidth(by: UInt64(feeBps))
            guard product.high < bpsScale else {
                return .max
            }

            return bpsScale.dividingFullWidth((high: product.high, low: product.low)).quotient
        }

        /// The value the program checks against both caps; `nil` when `amount + fee` overflows `u64`.
        static func total(amount: UInt64, feeBps: UInt16) -> UInt64? {
            let (result, overflow) = amount.addingReportingOverflow(fee(amount: amount, feeBps: feeBps))
            return overflow ? nil : result
        }

        /// A day bucket strictly behind `now` means the full budget. A bucket at or ahead of `now` means the
        /// device clock lags the cluster, so `spent_today` still counts — granting the full budget would pass
        /// a spin the program rejects. Clamps to zero: `spent_today` can legally exceed a cap lowered mid-day.
        public static func remainingToday(dailyCap: UInt64, spentToday: UInt64, dayIndex: Int64, now: Date) -> UInt64 {
            let today = Int64((now.timeIntervalSince1970 / secondsPerDay).rounded(.down))
            if dayIndex < today {
                return dailyCap
            }

            return dailyCap >= spentToday ? dailyCap - spentToday : 0
        }

        static func remainingToday(vault: Vault, now: Date) -> UInt64 {
            remainingToday(dailyCap: vault.dailyCap, spentToday: vault.spentToday, dayIndex: vault.dayIndex, now: now)
        }

        static func fitsCaps(amount: UInt64, vault: Vault, feeBps: UInt16, now: Date) -> Bool {
            guard let total = total(amount: amount, feeBps: feeBps) else {
                return false
            }

            return total <= vault.perSpinCap && total <= remainingToday(vault: vault, now: now)
        }
    }
}

// MARK: - Private implementation

/// Bounds-checked reads over raw account data.
private struct CollectiblesAccountReader {
    let data: Data

    func requireDiscriminator(_ discriminator: Data) throws {
        guard data.count >= 8, Data(data.prefix(8)) == discriminator else {
            throw CollectiblesVaultProgram.ProgramError.invalidAccountData
        }
    }

    func requireCount(_ count: Int) throws {
        guard data.count >= count else {
            throw CollectiblesVaultProgram.ProgramError.invalidAccountData
        }
    }

    func bytes(at offset: Int, count: Int) throws -> Data {
        try requireCount(offset + count)
        return Data(data.subdata(in: data.startIndex + offset ..< data.startIndex + offset + count))
    }

    func byte(at offset: Int) throws -> UInt8 {
        try bytes(at: offset, count: 1)[0]
    }

    func bool(at offset: Int) throws -> Bool {
        switch try byte(at: offset) {
        case 0:
            return false
        case 1:
            return true
        default:
            throw CollectiblesVaultProgram.ProgramError.invalidAccountData
        }
    }

    func uint16LE(at offset: Int) throws -> UInt16 {
        let bytes = try bytes(at: offset, count: 2)
        return UInt16(bytes[0]) | (UInt16(bytes[1]) << 8)
    }

    func uint64LE(at offset: Int) throws -> UInt64 {
        let bytes = try bytes(at: offset, count: 8)
        return bytes.reversed().reduce(UInt64(0)) { ($0 << 8) | UInt64($1) }
    }
}

private extension Data {
    mutating func appendLittleEndian(_ value: UInt64) {
        Swift.withUnsafeBytes(of: value.littleEndian) { append(contentsOf: $0) }
    }

    mutating func appendBorshString(_ string: String) {
        let utf8 = Data(string.utf8)
        Swift.withUnsafeBytes(of: UInt32(utf8.count).littleEndian) { append(contentsOf: $0) }
        append(utf8)
    }

    mutating func appendBorshOption(_ value: Data?) {
        guard let value else {
            return append(0)
        }

        append(1)
        append(value)
    }

    mutating func appendBorshOption(_ value: UInt64?) {
        guard let value else {
            return append(0)
        }

        append(1)
        appendLittleEndian(value)
    }
}
