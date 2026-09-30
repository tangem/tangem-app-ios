//
//  TonConnectSendTransactionValidator.swift
//  TangemModules
//
//  Created by Dean Rie
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BigInt
import Foundation
import TonSwift

/// The account a session is bound to, as seen by the validator.
public struct TonConnectWalletAccount: Equatable {
    public let address: Address
    public let network: TonConnectNetworkID
    /// Maximum outgoing messages the wallet contract accepts in one transfer (4 for wallet v4).
    public let maxMessages: Int

    public init(address: Address, network: TonConnectNetworkID, maxMessages: Int = TonConnectSendTransactionValidator.walletV4MaxMessages) {
        self.address = address
        self.network = network
        self.maxMessages = maxMessages
    }
}

/// A `sendTransaction` / `signMessage` payload that passed every rule of `guides/send-transaction.md`.
public struct TonConnectValidatedTransaction: Equatable {
    public struct Message: Equatable {
        public let destination: Address
        /// Extracted from the user-friendly address flag, as the spec requires.
        public let bounce: Bool
        /// Nanocoins.
        public let amount: BigUInt
        public let payload: Cell?
        public let stateInit: Cell?

        public init(destination: Address, bounce: Bool, amount: BigUInt, payload: Cell?, stateInit: Cell?) {
            self.destination = destination
            self.bounce = bounce
            self.amount = amount
            self.payload = payload
            self.stateInit = stateInit
        }
    }

    /// Unix seconds after which the request must not be signed; `nil` when the dApp did not set it.
    public let validUntil: UInt64?
    public let messages: [Message]

    public var totalAmount: BigUInt {
        messages.reduce(BigUInt.zero) { $0 + $1.amount }
    }
}

/// Applies the wallet-side validation rules for `sendTransaction` and `signMessage` (`spec/rpc.md`,
/// `guides/send-transaction.md`). Every rejection is a `TonConnectError.badRequest` (code 1) with a
/// message the dApp developer can act on.
public struct TonConnectSendTransactionValidator: Sendable {
    public static let walletV4MaxMessages = 4

    private let now: @Sendable () -> Date

    public init(now: @escaping @Sendable () -> Date = { Date() }) {
        self.now = now
    }

    public func validate(_ payload: TonConnectSendTransactionPayload, for account: TonConnectWalletAccount) throws -> TonConnectValidatedTransaction {
        if payload.hasItems {
            guard payload.messages == nil else {
                throw TonConnectError.badRequest("payload must contain either messages or items, not both")
            }
            throw TonConnectError.badRequest("structured items are not supported by this wallet; send raw messages")
        }

        guard let messages = payload.messages else {
            throw TonConnectError.badRequest("payload must contain messages")
        }

        let validUntil = try validateValidUntil(payload.validUntil)

        if let network = payload.network, network != account.network {
            throw TonConnectError.badRequest("network \(network) does not match the connected account network \(account.network)")
        }

        if let from = payload.from {
            let fromAddress: Address
            do {
                fromAddress = try Address.parse(from)
            } catch {
                throw TonConnectError.badRequest("from is not a valid TON address")
            }
            guard fromAddress == account.address else {
                throw TonConnectError.badRequest("from does not match the connected account")
            }
        }

        guard !messages.isEmpty else {
            throw TonConnectError.badRequest("messages must not be empty")
        }

        guard messages.count <= account.maxMessages else {
            throw TonConnectError.badRequest("too many messages: \(messages.count), the wallet supports at most \(account.maxMessages)")
        }

        return TonConnectValidatedTransaction(
            validUntil: validUntil,
            messages: try messages.enumerated().map { index, message in
                try validate(message, index: index)
            }
        )
    }

    private func validateValidUntil(_ raw: Int64?) throws -> UInt64? {
        guard let raw else {
            return nil
        }

        let current = now().timeIntervalSince1970
        guard raw > 0 else {
            throw TonConnectError.badRequest("valid_until must be a positive unix timestamp")
        }
        guard TimeInterval(raw) > current else {
            throw TonConnectError.badRequest("request expired: valid_until \(raw) is in the past")
        }

        return UInt64(raw)
    }

    private func validate(_ message: TonConnectSendTransactionPayload.Message, index: Int) throws -> TonConnectValidatedTransaction.Message {
        let field = "messages[\(index)]"

        // The spec requires the user-friendly form: it carries the bounce flag the wallet must honour.
        guard !message.address.contains(":") else {
            throw TonConnectError.badRequest("\(field).address must be in user-friendly format, raw addresses are not allowed")
        }

        let friendly: FriendlyAddress
        do {
            friendly = try FriendlyAddress(string: message.address)
        } catch {
            throw TonConnectError.badRequest("\(field).address is not a valid TON address")
        }

        guard let amount = BigUInt(message.amount, radix: 10), !message.amount.isEmpty else {
            throw TonConnectError.badRequest("\(field).amount must be a non-negative decimal string of nanocoins")
        }

        // `Coins` is `VarUInteger 16`, i.e. at most 120 bits.
        guard amount.bitWidth <= 120 else {
            throw TonConnectError.badRequest("\(field).amount exceeds the maximum representable value")
        }

        if let extraCurrency = message.extraCurrency, !extraCurrency.isEmpty {
            throw TonConnectError.badRequest("\(field).extra_currency is not supported by this wallet")
        }

        let payload = try message.payload.map { try TonConnectBoc.singleRootCell(base64: $0, field: "\(field).payload") }
        let stateInit = try message.stateInit.map { try TonConnectBoc.singleRootCell(base64: $0, field: "\(field).stateInit") }

        if let stateInit {
            // Fail early on a stateInit the wallet contract could not serialise into the message.
            do {
                _ = try StateInit.loadFrom(slice: stateInit.beginParse())
            } catch {
                throw TonConnectError.badRequest("\(field).stateInit is not a valid StateInit cell")
            }
        }

        return TonConnectValidatedTransaction.Message(
            destination: friendly.address,
            bounce: friendly.isBounceable,
            amount: amount,
            payload: payload,
            stateInit: stateInit
        )
    }
}
