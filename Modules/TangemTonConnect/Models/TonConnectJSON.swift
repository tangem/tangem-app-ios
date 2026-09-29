//
//  TonConnectJSON.swift
//  TangemModules
//
//  Created by Dean Rie
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// JSON serialisation of outgoing wallet messages (`ConnectEvent`, `WalletResponse`, `DisconnectEvent`).
public enum TonConnectJSON {
    /// Plaintext bytes to hand to `TonConnectSessionCrypto.encrypt`.
    public static func encode<T: Encodable>(_ message: T) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.withoutEscapingSlashes, .sortedKeys]
        do {
            return try encoder.encode(message)
        } catch {
            throw TonConnectError.internalFailure("failed to encode outgoing message: \(error)")
        }
    }
}
