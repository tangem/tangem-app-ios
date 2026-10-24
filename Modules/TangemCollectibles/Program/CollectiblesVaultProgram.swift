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

/// Byte-level layer of the `tangem_gacha_vault` program: discriminators, borsh-encoded instruction
/// data, PDA derivations and on-chain account parsing. Only what the app consumes today is public;
/// the rest widens member by member as the onboarding ceremony and the RPC vault reader land.
public struct CollectiblesVaultProgram {
    public enum ProgramError: Error {
        case invalidProgramId
        case invalidPublicKey
        case invalidAccountData
        case invalidCaps
        case impossibleVaultAccount
        case invalidPurchase
    }

    public static let devnetProgramId = "29agFEruMu2jedVwnDgKPuq7ejmTiB7sEqzdhufQQS9u"

    let programId: PublicKey

    public init(programId: String) throws {
        guard let programId = PublicKey(string: programId), programId.data.count == PublicKey.LENGTH else {
            throw ProgramError.invalidProgramId
        }

        self.programId = programId
    }

    // MARK: - Discriminators

    static func instructionDiscriminator(_ name: String) -> Data {
        Data(SHA256.hash(data: Data(("global:" + name).utf8)).prefix(8))
    }

    static func accountDiscriminator(_ name: String) -> Data {
        Data(SHA256.hash(data: Data(("account:" + name).utf8)).prefix(8))
    }

    // MARK: - Addresses

    /// Base58 address of the program's singleton config PDA.
    public func configAddress() throws -> String {
        try configPDA().base58EncodedString
    }

    /// Base58 address of the token account the vault receives USDC on — the collectibles account's
    /// own address, derived rather than stored.
    public func vaultUsdcAddress(coldOwner: Data, usdcMint: Data) throws -> String {
        guard
            coldOwner.count == PublicKey.LENGTH, let coldOwnerKey = PublicKey(data: coldOwner),
            usdcMint.count == PublicKey.LENGTH, let mintKey = PublicKey(data: usdcMint)
        else {
            throw ProgramError.invalidPublicKey
        }

        let vault = try vaultPDA(coldOwner: coldOwnerKey)

        return try Self.associatedTokenAddress(owner: vault, mint: mintKey).base58EncodedString
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

    // MARK: - Config account

    /// Reads the program's singleton config. Unlike a missing vault, which means the wallet was never
    /// onboarded, a missing or foreign config means the program is not where we think it is — so this
    /// throws rather than answering `nil`.
    ///
    /// - Note: Never cache what this returns. The admin edits the config in place with `update_config`,
    ///   and a stale copy shows up on chain as `2012` — a constraint error naming an account we passed,
    ///   which reads as anything but "you are out of date".
    public func configInfo(accountOwner: String, accountData: Data) throws -> CollectiblesConfigInfo {
        guard accountOwner == programId.base58EncodedString else {
            throw ProgramError.invalidAccountData
        }

        let config = try Config(data: accountData)

        return CollectiblesConfigInfo(
            usdcMint: config.usdcMint,
            collectiblesUsdcAccount: config.collectiblesUsdcAccount,
            feeUsdcAccount: config.feeUsdcAccount,
            minFeeBps: config.minFeeBps,
            maxFeeBps: config.maxFeeBps
        )
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
            sessionKey: vault.sessionKey,
            perSpinCap: vault.perSpinCap,
            dailyCap: vault.dailyCap,
            spentToday: vault.spentToday,
            dayIndex: vault.dayIndex
        )
    }

    // MARK: - Vault USDC account

    public func vaultUsdcBalance(
        coldOwner: Data,
        usdcMint: Data,
        accountOwner: String,
        accountData: Data
    ) throws -> UInt64 {
        guard
            coldOwner.count == PublicKey.LENGTH, let coldOwnerKey = PublicKey(data: coldOwner),
            accountOwner == PublicKey.tokenProgramId.base58EncodedString
        else {
            throw ProgramError.invalidAccountData
        }

        let reader = CollectiblesAccountReader(data: accountData)
        try reader.requireCount(Constants.tokenAccountLength)

        guard
            try reader.bytes(at: 0, count: PublicKey.LENGTH) == usdcMint,
            try reader.bytes(at: 32, count: PublicKey.LENGTH) == vaultPDA(coldOwner: coldOwnerKey).data
        else {
            throw ProgramError.invalidAccountData
        }

        return try reader.uint64LE(at: 64)
    }

    // MARK: - Instructions

    /// The program's account order: vault, cold owner (read-only signer), payer (writable signer), system
    /// program. When the cold owner pays for itself the two signer slots collapse into one account whose
    /// flags merge, which is exactly what the message compiler produces.
    public func initVaultInstruction(
        coldOwner: Data,
        payer: Data,
        sessionKey: Data,
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
            sessionKey: sessionKey,
            perSpinCap: perSpinCap,
            dailyCap: dailyCap
        )

        // An instruction that allocates an account takes the System Program in its account list — a
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

    /// Creates the vault's USDC token account, or does nothing if it is already there. Belongs to the
    /// associated token program, not this one, so it can be bundled with `init_vault` — the vault owns
    /// the account but does not authorise its creation, and the payer's signature is the only one asked
    /// for, which is also what makes an off-curve owner legal.
    ///
    /// - Note: The idempotent variant. The plain one, which every SDK builder emits, fails on an account
    ///   that already exists and would take the whole transaction with it.
    public func createVaultUsdcInstruction(payer: Data, coldOwner: Data, usdcMint: Data) throws -> CollectiblesInstruction {
        guard
            payer.count == PublicKey.LENGTH, let payerKey = PublicKey(data: payer),
            coldOwner.count == PublicKey.LENGTH, let coldOwnerKey = PublicKey(data: coldOwner),
            usdcMint.count == PublicKey.LENGTH, let mintKey = PublicKey(data: usdcMint)
        else {
            throw ProgramError.invalidPublicKey
        }

        let vault = try vaultPDA(coldOwner: coldOwnerKey)
        let vaultUsdc = try Self.associatedTokenAddress(owner: vault, mint: mintKey)

        return CollectiblesInstruction(
            programId: PublicKey.splAssociatedTokenAccountProgramId.base58EncodedString,
            accounts: [
                .init(address: payerKey.base58EncodedString, isSigner: true, isWritable: true),
                .init(address: vaultUsdc.base58EncodedString, isSigner: false, isWritable: true),
                .init(address: vault.base58EncodedString, isSigner: false, isWritable: false),
                .init(address: mintKey.base58EncodedString, isSigner: false, isWritable: false),
                .init(address: PublicKey.programId.base58EncodedString, isSigner: false, isWritable: false),
                .init(address: PublicKey.tokenProgramId.base58EncodedString, isSigner: false, isWritable: false),
            ],
            data: Data([Constants.createIdempotentInstructionTag])
        )
    }

    /// Accounts: vault (the account being closed), cold owner (writable signer — the rent lands on it).
    /// Takes no arguments. The vault's token accounts are not touched: closing them is a separate
    /// instruction, and a vault closed before them leaves their rent stranded until one is deployed again
    /// for the same owner.
    public func closeVaultInstruction(coldOwner: Data) throws -> CollectiblesInstruction {
        guard coldOwner.count == PublicKey.LENGTH, let coldOwnerKey = PublicKey(data: coldOwner) else {
            throw ProgramError.invalidPublicKey
        }

        return CollectiblesInstruction(
            programId: programId.base58EncodedString,
            accounts: [
                .init(address: try vaultPDA(coldOwner: coldOwnerKey).base58EncodedString, isSigner: false, isWritable: true),
                .init(address: coldOwnerKey.base58EncodedString, isSigner: true, isWritable: true),
            ],
            data: Self.instructionDiscriminator("close_vault")
        )
    }

    /// Accounts: vault, cold owner (read-only signer). No payer — nothing is allocated here,
    /// and the fee payer is a transaction-level slot, not an instruction account.
    public func updateVaultInstruction(
        coldOwner: Data,
        sessionKey: Data?,
        perSpinCap: UInt64?,
        dailyCap: UInt64?
    ) throws -> CollectiblesInstruction {
        guard coldOwner.count == PublicKey.LENGTH, let coldOwnerKey = PublicKey(data: coldOwner) else {
            throw ProgramError.invalidPublicKey
        }

        let data = try Self.updateVaultInstructionData(
            sessionKey: sessionKey,
            perSpinCap: perSpinCap,
            dailyCap: dailyCap
        )

        return CollectiblesInstruction(
            programId: programId.base58EncodedString,
            accounts: [
                .init(address: try vaultPDA(coldOwner: coldOwnerKey).base58EncodedString, isSigner: false, isWritable: true),
                .init(address: coldOwnerKey.base58EncodedString, isSigner: true, isWritable: false),
            ],
            data: data
        )
    }

    public func purchasePackInstruction(
        coldOwner: Data,
        sessionKey: Data,
        config: CollectiblesConfigInfo,
        amount: UInt64,
        feeAmount: UInt64,
        memo: String
    ) throws -> CollectiblesInstruction {
        guard
            coldOwner.count == PublicKey.LENGTH, let coldOwnerKey = PublicKey(data: coldOwner),
            sessionKey.count == PublicKey.LENGTH, let sessionKeyKey = PublicKey(data: sessionKey),
            config.usdcMint.count == PublicKey.LENGTH, let mintKey = PublicKey(data: config.usdcMint),
            config.collectiblesUsdcAccount.count == PublicKey.LENGTH,
            let collectiblesUsdcKey = PublicKey(data: config.collectiblesUsdcAccount),
            config.feeUsdcAccount.count == PublicKey.LENGTH, let feeUsdcKey = PublicKey(data: config.feeUsdcAccount)
        else {
            throw ProgramError.invalidPublicKey
        }

        let data = try Self.purchasePackInstructionData(amount: amount, feeAmount: feeAmount, memo: memo)
        let vault = try vaultPDA(coldOwner: coldOwnerKey)
        let vaultUsdc = try Self.associatedTokenAddress(owner: vault, mint: mintKey)

        return CollectiblesInstruction(
            programId: programId.base58EncodedString,
            accounts: [
                .init(address: try configPDA().base58EncodedString, isSigner: false, isWritable: false),
                .init(address: vault.base58EncodedString, isSigner: false, isWritable: true),
                .init(address: sessionKeyKey.base58EncodedString, isSigner: true, isWritable: false),
                .init(address: mintKey.base58EncodedString, isSigner: false, isWritable: false),
                .init(address: vaultUsdc.base58EncodedString, isSigner: false, isWritable: true),
                .init(address: collectiblesUsdcKey.base58EncodedString, isSigner: false, isWritable: true),
                .init(address: feeUsdcKey.base58EncodedString, isSigner: false, isWritable: true),
                .init(address: PublicKey.tokenProgramId.base58EncodedString, isSigner: false, isWritable: false),
            ],
            data: data
        )
    }

    // MARK: - Instruction data

    static func initVaultInstructionData(sessionKey: Data, perSpinCap: UInt64, dailyCap: UInt64) throws -> Data {
        guard sessionKey.count == PublicKey.LENGTH else {
            throw ProgramError.invalidPublicKey
        }

        try validateCaps(perSpinCap: perSpinCap, dailyCap: dailyCap)

        var data = instructionDiscriminator("init_vault")
        data.append(sessionKey)
        data.appendLittleEndian(perSpinCap)
        data.appendLittleEndian(dailyCap)
        return data
    }

    /// Rotates the session key and/or the caps; `nil` leaves a field as the chain holds it.
    /// - Warning: The program checks `0 < per_spin_cap <= daily_cap` against the *combined* state, so one cap
    /// alone can fail with `6004` because of the value already stored for the other.
    static func updateVaultInstructionData(
        sessionKey: Data?,
        perSpinCap: UInt64?,
        dailyCap: UInt64?
    ) throws -> Data {
        // Borsh reads a `Pubkey` as fixed 32 bytes — a shorter one shifts every following field
        // and hands the vault to a session key nobody holds
        if let sessionKey, sessionKey.count != PublicKey.LENGTH {
            throw ProgramError.invalidPublicKey
        }

        try validateCaps(perSpinCap: perSpinCap, dailyCap: dailyCap)

        var data = instructionDiscriminator("update_vault")
        data.appendBorshOption(sessionKey)
        data.appendBorshOption(perSpinCap)
        data.appendBorshOption(dailyCap)

        return data
    }

    static func purchasePackInstructionData(amount: UInt64, feeAmount: UInt64, memo: String) throws -> Data {
        let memoBytes = Data(memo.utf8)

        guard amount > 0, !memoBytes.isEmpty, memoBytes.count <= Constants.maxMemoLength else {
            throw ProgramError.invalidPurchase
        }

        var data = instructionDiscriminator("purchase_pack")
        data.appendLittleEndian(amount)
        data.appendLittleEndian(feeAmount)
        data.appendBorshString(memoBytes)
        return data
    }

    /// The program's `0 < per_spin_cap <= daily_cap` rule (error `6004`), checked before the card tap.
    /// A `nil` cap keeps the stored value, which the pair check can't see — but a zero fails on its own,
    /// since `per_spin_cap` must be positive and a stored one never is zero.
    private static func validateCaps(perSpinCap: UInt64?, dailyCap: UInt64?) throws {
        if perSpinCap == 0 || dailyCap == 0 {
            throw ProgramError.invalidCaps
        }

        if let perSpinCap, let dailyCap, perSpinCap > dailyCap {
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
        let minFeeBps: UInt16
        let maxFeeBps: UInt16
        let paused: Bool
        let allowBuybackDelegation: Bool
        let bump: UInt8
    }

    struct Vault {
        let coldOwner: Data
        let sessionKey: Data
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
    /// 176-byte layout with fixed offsets; the length check is a lower bound, not an exact size.
    /// Byte 171 is a legacy `_reserved` filler that can legitimately hold garbage.
    init(data: Data) throws {
        let reader = CollectiblesAccountReader(data: data)
        try reader.requireDiscriminator(CollectiblesVaultProgram.accountDiscriminator("Config"))
        try reader.requireCount(176)

        admin = try reader.bytes(at: 8, count: 32)
        usdcMint = try reader.bytes(at: 40, count: 32)
        collectiblesWallet = try reader.bytes(at: 72, count: 32)
        collectiblesUsdcAccount = try reader.bytes(at: 104, count: 32)
        feeUsdcAccount = try reader.bytes(at: 136, count: 32)
        minFeeBps = try reader.uint16LE(at: 168)
        maxFeeBps = try reader.uint16LE(at: 174)
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
        sessionKey = try reader.bytes(at: 40, count: 32)
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
    /// Limit checks mirror the program exactly: lazy UTC day bucket, clamp-to-zero remainder.
    enum SpendingMath {
        /// A day bucket strictly behind `now` means the full budget. A bucket at or ahead of `now` means the
        /// device clock lags the cluster, so `spent_today` still counts — granting the full budget would pass
        /// a spin the program rejects. Clamps to zero: `spent_today` can legally exceed a cap lowered mid-day.
        public static func remainingToday(dailyCap: UInt64, spentToday: UInt64, dayIndex: Int64, now: Date) -> UInt64 {
            let today = Int64((now.timeIntervalSince1970 / Constants.secondsPerDay).rounded(.down))
            if dayIndex < today {
                return dailyCap
            }

            return dailyCap >= spentToday ? dailyCap - spentToday : 0
        }

        static func remainingToday(vault: Vault, now: Date) -> UInt64 {
            remainingToday(dailyCap: vault.dailyCap, spentToday: vault.spentToday, dayIndex: vault.dayIndex, now: now)
        }

        /// - Parameter feeAmount: the backend's `fee_amount` — the program checks the caps against `amount + fee_amount`.
        static func fitsCaps(amount: UInt64, feeAmount: UInt64, vault: Vault, now: Date) -> Bool {
            fitsCaps(
                amount: amount,
                feeAmount: feeAmount,
                perSpinCap: vault.perSpinCap,
                remainingToday: remainingToday(vault: vault, now: now)
            )
        }

        static func fitsCaps(amount: UInt64, feeAmount: UInt64, vault: CollectiblesVaultInfo, now: Date) -> Bool {
            fitsCaps(
                amount: amount,
                feeAmount: feeAmount,
                perSpinCap: vault.perSpinCap,
                remainingToday: vault.remainingToday(now: now)
            )
        }

        public static func feeCorridor(amount: UInt64, config: CollectiblesConfigInfo) -> ClosedRange<UInt64> {
            let lower = feeBound(amount: amount, bps: min(config.minFeeBps, config.maxFeeBps))
            let upper = feeBound(amount: amount, bps: max(config.minFeeBps, config.maxFeeBps))

            return lower ... upper
        }

        /// A fee outside the corridor is rejected on chain, so the sponsor's `fee_amount` is worth checking
        /// before the spin is signed.
        public static func fitsFeeCorridor(amount: UInt64, feeAmount: UInt64, config: CollectiblesConfigInfo) -> Bool {
            feeCorridor(amount: amount, config: config).contains(feeAmount)
        }

        private static func fitsCaps(
            amount: UInt64,
            feeAmount: UInt64,
            perSpinCap: UInt64,
            remainingToday: UInt64
        ) -> Bool {
            let (total, overflow) = amount.addingReportingOverflow(feeAmount)

            guard !overflow else {
                return false
            }

            return total <= perSpinCap && total <= remainingToday
        }

        /// `amount * bps / 10_000` without the overflow the intermediate product hits for large amounts.
        private static func feeBound(amount: UInt64, bps: UInt16) -> UInt64 {
            let product = amount.multipliedFullWidth(by: UInt64(bps))

            // The divisor exceeds the high half, so the quotient always fits and the trap cannot fire
            return product.high < Constants.bpsDenominator
                ? Constants.bpsDenominator.dividingFullWidth(product).quotient
                : .max
        }
    }
}

// MARK: - Constants

private extension CollectiblesVaultProgram {
    enum Constants {
        /// `CreateIdempotent` in the associated token program; `0` is the plain `Create`.
        static let createIdempotentInstructionTag: UInt8 = 1
        static let tokenAccountLength = 165
        static let maxMemoLength = 256
    }
}

private extension CollectiblesVaultProgram.SpendingMath {
    enum Constants {
        static let secondsPerDay: TimeInterval = 86_400
        static let bpsDenominator: UInt64 = 10_000
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

    mutating func appendBorshString(_ bytes: Data) {
        Swift.withUnsafeBytes(of: UInt32(bytes.count).littleEndian) { append(contentsOf: $0) }
        append(bytes)
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
