//
//  TangemPayIdempotencyKey.swift
//  TangemModules
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import CryptoKit
import Foundation

public enum TangemPayIdempotencyKey {
    public static func make(_ components: String...) -> String {
        let input = components.joined(separator: "|")
        let digest = SHA256.hash(data: Data(input.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
