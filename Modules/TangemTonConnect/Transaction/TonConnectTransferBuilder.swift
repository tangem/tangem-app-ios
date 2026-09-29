//
//  TonConnectTransferBuilder.swift
//  TangemModules
//
//  Created by Dean Rie
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TonSwift

/// Builds and signs the wallet-v4R2 external message for a validated `sendTransaction` request.
///
/// The existing `TONTransactionBuilder` in BlockchainSdk goes through WalletCore, whose `Transfer`
/// message only supports a text comment or a jetton transfer. dApps send arbitrary `payload` /
/// `stateInit` cells, so TON Connect transfers are assembled with TonSwift instead — the same
/// contract code, wallet id and signing layout, just with caller-supplied bodies.
public struct TonConnectTransferBuilder {
    /// Default lifetime of the signed message when the dApp did not set `valid_until`.
    public static let defaultTimeout: TimeInterval = 5 * 60

    /// Outgoing messages are sent with mode 3 (`PAY_GAS_SEPARATELY | IGNORE_ERRORS`), as the spec requires.
    public static let sendMode = SendMode.walletDefault()

    /// Everything needed to sign and later assemble the external message.
    public struct Prepared {
        /// 32-byte hash of the signing message — this is what the card signs.
        public let hashToSign: Data
        /// Unix seconds; the transfer is rejected by the contract after this moment.
        public let expiresAt: UInt64
        let signingMessage: Cell
        let walletAddress: Address
        let stateInit: StateInit?
    }

    private let contract: WalletV4R2
    private let now: () -> Date

    /// - Parameter publicKey: the account's 32-byte Ed25519 public key.
    public init(publicKey: Data, workchain: Int8 = 0, now: @escaping () -> Date = Date.init) throws {
        guard publicKey.count == 32 else {
            throw TonConnectError.internalFailure("TON public key must be 32 bytes")
        }
        contract = WalletV4R2(workchain: workchain, publicKey: publicKey)
        self.now = now
    }

    public var address: Address {
        get throws { try contract.address() }
    }

    /// Serialises the wallet's `StateInit` (standard base64 BoC) for the `ton_addr` reply.
    public func stateInitBoc() throws -> String {
        try TonConnectBoc.base64(try Builder().store(contract.stateInit).endCell())
    }

    /// Builds the unsigned transfer. `seqno` is the account's current sequence number; `0` means the
    /// contract is not deployed yet and its `StateInit` is attached to the external message.
    public func prepare(_ transaction: TonConnectValidatedTransaction, seqno: UInt32) throws -> Prepared {
        let messages = try transaction.messages.map(makeInternalMessage)

        let expiresAt = expiration(validUntil: transaction.validUntil)
        let transfer = try contract.createTransfer(
            args: WalletTransferData(seqno: UInt64(seqno), messages: messages, sendMode: Self.sendMode, timeout: expiresAt),
            messageType: .ext
        )

        let signingMessage = try transfer.signingMessage.endCell()

        return Prepared(
            hashToSign: signingMessage.hash(),
            expiresAt: expiresAt,
            signingMessage: signingMessage,
            walletAddress: try contract.address(),
            stateInit: seqno == 0 ? contract.stateInit : nil
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
            .store(slice: prepared.signingMessage.beginParse())
            .endCell()

        let external = Message.external(to: prepared.walletAddress, stateInit: prepared.stateInit, body: body)
        let cell = try Builder().store(external).endCell()
        return try TonConnectBoc.base64(cell)
    }

    /// `prepare` + sign + `assemble` in one step.
    public func sign(_ transaction: TonConnectValidatedTransaction, seqno: UInt32, signer: any TonConnectSigner) async throws -> String {
        let prepared = try prepare(transaction, seqno: seqno)
        let signature = try await signer.sign(digest: prepared.hashToSign)
        return try assemble(prepared, signature: signature)
    }

    private func makeInternalMessage(_ message: TonConnectValidatedTransaction.Message) throws -> MessageRelaxed {
        let stateInit = try message.stateInit.map { try StateInit.loadFrom(slice: $0.beginParse()) }

        // `Cell.empty` is a bare placeholder without precomputed hashes in TonSwift; build a real empty cell.
        let body = try message.payload ?? Builder().endCell()

        return MessageRelaxed.internal(
            to: message.destination,
            value: message.amount,
            bounce: message.bounce,
            stateInit: stateInit,
            body: body
        )
    }

    private func expiration(validUntil: UInt64?) -> UInt64 {
        let fallback = UInt64(now().timeIntervalSince1970 + Self.defaultTimeout)
        guard let validUntil else {
            return fallback
        }
        // Honour the dApp's deadline but never let a signed message outlive the wallet's own bound.
        return min(validUntil, fallback)
    }
}
