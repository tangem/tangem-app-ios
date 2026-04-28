//
//  StringHashCollisionTests.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import CryptoKit
import Foundation
import Testing

/// Pins why `TangemPayAuthorizationAPITarget` uses `.sha256()` instead of
/// `.hash` to derive the refresh-token idempotency key.
///
/// `.hash` is the bridged `NSString.hash`, which for inputs longer than 96
/// characters samples only `[0..32) ∪ [length/2-16..length/2+16) ∪
/// [length-32..length)`, so distinct inputs differing in unsampled positions
/// hash identically — collapsing two refresh tokens to the same key.
@Suite("Refresh-token idempotency-key hashing")
struct StringHashCollisionTests {
    @Test(".hash collapses distinct inputs to the same value (bug)")
    func hashCollidesOnDistinctInputs() {
        let (a, b) = collidingPair()
        #expect(a != b)
        #expect(a.hash == b.hash)
    }

    @Test(".sha256() returns distinct digests for those same distinct inputs (fix)")
    func sha256DistinguishesDistinctInputs() {
        let (a, b) = collidingPair()
        #expect(a != b)
        #expect(sha256Hex(a) != sha256Hex(b))
    }

    @Test(".sha256() returns the same digest for the same input (retries)")
    func sha256IsDeterministicForSameInput() {
        let input = "OGM3ZjRkYjctYjE0Mi00MWU4LWIwYWQtMWI5YmYzZmVjZGE0OnM0bFRpSTc1QjNYXzl3Y29NeXdOS0RjRi16cW1oUFM3VFEtU2NUbzlSVlU"
        #expect(sha256Hex(input) == sha256Hex(input))
    }

    /// Two 200-char strings sharing the three NSString.hash sampling windows
    /// `[0..32) ∪ [84..116) ∪ [168..200)` and differing only in the unsampled
    /// gaps, which is enough to force a `.hash` collision.
    private func collidingPair() -> (String, String) {
        let head = String(repeating: "A", count: 32)
        let middle = String(repeating: "M", count: 32)
        let tail = String(repeating: "Z", count: 32)
        let a = head
            + String(repeating: "1", count: 52)
            + middle
            + String(repeating: "2", count: 52)
            + tail
        let b = head
            + String(repeating: "X", count: 52)
            + middle
            + String(repeating: "Y", count: 52)
            + tail
        return (a, b)
    }

    /// SHA-256 of the UTF-8 bytes, lowercase hex. Byte-identical to the
    /// `CryptoSwift.String.sha256()` call used in `TangemPayAuthorizationAPITarget`.
    private func sha256Hex(_ string: String) -> String {
        SHA256.hash(data: Data(string.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}
