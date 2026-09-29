//
//  TonConnectSignDataValidator.swift
//  TangemModules
//
//  Created by Dean Rie
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TonSwift

/// Wallet-side rules for `signData` (`spec/rpc.md` § signData): the request must target the connected
/// account and its network, and the wallet must have advertised the payload type.
///
/// Without this check a dApp could obtain a signature bound to another network (`-3` vs `-239`) or ask the
/// wallet to sign "for" an address it did not connect — the digest only binds what the wallet puts into it.
public struct TonConnectSignDataValidator: Sendable {
    /// Upper bound on `text` / `binary` payload size; long content cannot be reviewed on a phone screen.
    public static let maxPayloadByteCount = 64 * 1024

    public init() {}

    public func validate(
        _ payload: TonConnectSignDataPayload,
        for account: TonConnectWalletAccount,
        supportedTypes: Set<TonConnectSignDataType>
    ) throws {
        guard supportedTypes.contains(payload.content.type) else {
            throw TonConnectError.badRequest("signData type \(payload.content.type.rawValue) is not supported by this wallet")
        }

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

        switch payload.content {
        case .text(let text):
            guard text.utf8.count <= Self.maxPayloadByteCount else {
                throw TonConnectError.badRequest("text payload exceeds \(Self.maxPayloadByteCount) bytes")
            }
        case .binary(let bytes):
            guard bytes.count <= Self.maxPayloadByteCount else {
                throw TonConnectError.badRequest("binary payload exceeds \(Self.maxPayloadByteCount) bytes")
            }
        case .cell(_, let cellBoc):
            // Parsed (and structurally preflighted) once here so a malformed cell is a clean BAD_REQUEST
            // before any UI is shown; the digest builder parses it again.
            _ = try TonConnectBoc.singleRootCell(base64: cellBoc, field: "cell")
        }
    }
}
