//
//  TangemPayIdempotencyKey.swift
//  TangemModules
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import CryptoKit
import Foundation

/// Builds the `Idempotency-Key` header value sent with `POST /order`. Components are joined
/// by `|`, then SHA256-hashed and hex-encoded. The same components must always produce the
/// same key — that's the contract the BFF relies on to dedupe retries.
public enum TangemPayIdempotencyKey {
    public static func make(_ components: String...) -> String {
        let input = components.joined(separator: "|")
        let digest = SHA256.hash(data: Data(input.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
