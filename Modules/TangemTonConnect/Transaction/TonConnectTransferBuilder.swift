//
//  TonConnectTransferBuilder.swift
//  TangemModules
//
//  Created by Dean Rie
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BigInt
import Foundation
import TonSwift

/// Builds and signs the wallet-v4R2 external message for a validated `sendTransaction` request.
///
/// The existing `TONTransactionBuilder` in BlockchainSdk goes through WalletCore, whose `Transfer`
/// message only supports a text comment or a jetton transfer. dApps send arbitrary `payload` /
/// `stateInit` cells, so TON Connect transfers are assembled here with TonSwift's cell `Builder` —
/// the same contract code, wallet id and signing layout, just with caller-supplied bodies.
///
/// dApp-supplied cells are only ever copied bit-for-bit into the message (`Either X ^X`); they are
/// never re-parsed through TonSwift's typed decoders (`StateInit.loadFrom`, `MessageRelaxed`), whose
/// dictionary reader traps on hostile labels. Inline-vs-reference decisions follow `@ton/core` and the
/// Android module so the signed bytes are identical across platforms.
public struct TonConnectTransferBuilder {
    /// Default lifetime of the signed message when the dApp did not set `valid_until`.
    public static let defaultTimeout: TimeInterval = 5 * 60

    /// Outgoing messages are sent with mode 3 (`PAY_GAS_SEPARATELY | IGNORE_ERRORS`), as the spec requires.
    public static let sendMode: UInt8 = 3

    /// Everything needed to sign and later assemble the external message.
    public struct Prepared {
        /// 32-byte hash of the signing message — this is what the card signs.
        public let hashToSign: Data
        /// Unix seconds; the transfer is rejected by the contract after this moment.
        public let expiresAt: UInt64
        let signingMessage: Cell
        let walletAddress: Address
        let stateInit: Cell?
    }

    private let contract: WalletV4R2
    private let walletStateInit: Cell
    private let walletAddress: Address
    private let now: () -> Date

    /// - Parameter publicKey: the account's 32-byte Ed25519 public key.
    public init(publicKey: Data, workchain: Int8 = 0, now: @escaping () -> Date = Date.init) throws {
        guard publicKey.count == 32 else {
            throw TonConnectError.internalFailure("TON public key must be 32 bytes")
        }
        contract = WalletV4R2(workchain: workchain, publicKey: publicKey)
        walletStateInit = try Builder().store(contract.stateInit).endCell()
        walletAddress = Address(workchain: workchain, hash: walletStateInit.hash())
        self.now = now
    }

    public var address: Address { walletAddress }

    /// Serialises the wallet's `StateInit` (standard base64 BoC) for the `ton_addr` reply.
    public func stateInitBoc() throws -> String {
        try TonConnectBoc.base64(walletStateInit)
    }

    /// Builds the unsigned transfer. `seqno` is the account's current sequence number; `0` means the
    /// contract is not deployed yet and its `StateInit` is attached to the external message.
    public func prepare(_ transaction: TonConnectValidatedTransaction, seqno: UInt32) throws -> Prepared {
        guard transaction.messages.count <= TonConnectSendTransactionValidator.walletV4MaxMessages else {
            throw TonConnectError.badRequest("wallet v4 accepts at most 4 messages per transfer")
        }

        let expiresAt = expiration(validUntil: transaction.validUntil)

        // wallet-v4: subwallet_id:uint32 valid_until:uint32 seqno:uint32 op:uint8 (mode:uint8 ^MessageRelaxed)*
        let signingMessage = try Builder()
            .store(uint: contract.walletId, bits: 32)
            .store(uint: expiresAt, bits: 32)
            .store(uint: seqno, bits: 32)
            .store(uint: 0, bits: 8)
        for message in transaction.messages {
            try signingMessage.store(uint: Self.sendMode, bits: 8)
            try signingMessage.store(ref: try internalMessage(message))
        }
        let signingCell = try signingMessage.endCell()

        return Prepared(
            hashToSign: signingCell.hash(),
            expiresAt: expiresAt,
            signingMessage: signingCell,
            walletAddress: walletAddress,
            stateInit: seqno == 0 ? walletStateInit : nil
        )
    }

    /// Wraps the signature and the signing message into the external message the network accepts.
    /// Returns the standard base64 BoC that is both broadcast and returned to the dApp as `result`.
    public func assemble(_ prepared: Prepared, signature: Data) throws -> String {
        guard signature.count == 64 else {
            throw TonConnectError.internalFailure("signature must be 64 bytes, got \(signature.count)")
        }

        // Wallet v4 expects `signature ++ signing_message` as the external message body.
        let body = try Builder()
            .store(data: signature)
            .store(bits: prepared.signingMessage.bits)
        for ref in prepared.signingMessage.refs {
            try body.store(ref: ref)
        }

        // ext_in_msg_info$10 src:addr_none dest:MsgAddressInt import_fee:Coins init:(Maybe (Either StateInit ^StateInit)) body:(Either X ^X)
        let external = try Builder()
            .store(bit: true).store(bit: false)
            .store(bit: false).store(bit: false)
            .store(prepared.walletAddress)
        try Self.storeCoins(.zero, to: external)
        try Self.storeMaybeEither(prepared.stateInit, reservedBits: 2, to: external)
        try Self.storeEither(try body.endCell(), reservedBits: 1, to: external)

        return try TonConnectBoc.base64(try external.endCell())
    }

    /// `prepare` + sign + `assemble` in one step.
    public func sign(_ transaction: TonConnectValidatedTransaction, seqno: UInt32, signer: any TonConnectSigner) async throws -> String {
        let prepared = try prepare(transaction, seqno: seqno)
        let signature = try await signer.sign(digest: prepared.hashToSign)
        return try assemble(prepared, signature: signature)
    }

    // MARK: - TL-B serialisation

    /// `int_msg_info$0` relaxed message with the dApp-supplied body and optional deploy `StateInit`.
    private func internalMessage(_ message: TonConnectValidatedTransaction.Message) throws -> Cell {
        let builder = try Builder()
            .store(bit: false) // int_msg_info$0
            .store(bit: true) // ihr_disabled
            .store(bit: message.bounce)
            .store(bit: false) // bounced
            .store(bit: false).store(bit: false) // src: addr_none
            .store(message.destination)
        try Self.storeCoins(message.amount, to: builder)
        try builder.store(bit: false) // extra currencies: empty
        try Self.storeCoins(.zero, to: builder) // ihr_fee
        try Self.storeCoins(.zero, to: builder) // fwd_fee
        try builder.store(uint: 0, bits: 64) // created_lt
        try builder.store(uint: 0, bits: 32) // created_at
        try Self.storeMaybeEither(message.stateInit, reservedBits: 2, to: builder)
        try Self.storeEither(message.payload ?? Builder().endCell(), reservedBits: 1, to: builder)
        return try builder.endCell()
    }

    /// `VarUInteger 16` (Coins): 4-bit byte-length prefix followed by the big-endian magnitude.
    static func storeCoins(_ value: BigUInt, to builder: Builder) throws {
        guard value.bitWidth <= 120 else {
            throw TonConnectError.badRequest("amount exceeds the maximum representable value")
        }
        if value.isZero {
            try builder.store(uint: 0, bits: 4)
            return
        }
        let magnitude = value.serialize()
        try builder.store(uint: magnitude.count, bits: 4)
        try builder.store(data: magnitude)
    }

    /// `Maybe (Either X ^X)`: absent → `0`; present → `1` then inline or ref like `storeEither`.
    private static func storeMaybeEither(_ cell: Cell?, reservedBits: Int, to builder: Builder) throws {
        guard let cell else {
            try builder.store(bit: false)
            return
        }
        try builder.store(bit: true)
        try storeEither(cell, reservedBits: reservedBits, to: builder)
    }

    /// `Either X ^X`: inline (`0`) when the cell fits with `reservedBits` to spare, otherwise by reference (`1`).
    private static func storeEither(_ cell: Cell, reservedBits: Int, to builder: Builder) throws {
        let fitsInline = builder.availableBits - cell.bits.length >= reservedBits && builder.availableRefs >= cell.refs.count
        if fitsInline {
            try builder.store(bit: false)
            try builder.store(bits: cell.bits)
            for ref in cell.refs {
                try builder.store(ref: ref)
            }
        } else {
            try builder.store(bit: true)
            try builder.store(ref: cell)
        }
    }

    private func expiration(validUntil: UInt64?) -> UInt64 {
        let fallback = UInt64(now().timeIntervalSince1970 + Self.defaultTimeout)
        guard let validUntil else {
            return fallback
        }
        // Honour the dApp's deadline but never let a signed message outlive the wallet's own bound.
        return min(validUntil, fallback)
    }

    /// Cheap structural check that a dApp-supplied cell is a `StateInit` this wallet will forward:
    /// `split_depth:(Maybe (## 5)) special:(Maybe TickTock) code:(Maybe ^Cell) data:(Maybe ^Cell) library:(HashmapE 256 SimpleLib)`
    /// with an *empty* library dictionary — libraries are exotic cells, which `TonConnectBoc` rejects anyway,
    /// and parsing a hostile `HashmapE` is exactly what this check keeps out of TonSwift.
    static func isForwardableStateInit(_ cell: Cell) -> Bool {
        do {
            let slice = try cell.beginParse()
            var refsNeeded = 0
            if try slice.loadBit() == 1 { _ = try slice.loadUint(bits: 5) } // split_depth
            if try slice.loadBit() == 1 { _ = try slice.loadBits(2) } // special: TickTock
            if try slice.loadBit() == 1 { refsNeeded += 1 } // code
            if try slice.loadBit() == 1 { refsNeeded += 1 } // data
            guard try slice.loadBit() == 0 else { return false } // library must be empty
            return cell.refs.count == refsNeeded && slice.remainingBits == 0
        } catch {
            return false
        }
    }
}
