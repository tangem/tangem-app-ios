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

/// Pins the behavior of `String.hash` (bridged from `NSString.hash`):
/// for inputs longer than 96 characters it samples only
/// `[0..32) ∪ [length/2-16..length/2+16) ∪ [length-32..length)`,
/// so strings differing only in unsampled positions hash identically.
///
/// Captured here so we don't accidentally rely on `.hash` for distinctness
/// (e.g. as an idempotency key).
@Suite("String.hash collision behavior")
struct StringHashCollisionTests {
    @Test("Distinct short strings produce distinct hashes")
    func distinctShortStringsHaveDistinctHashes() {
        let a = "hello"
        let b = "world"
        #expect(a != b)
        #expect(a.hash != b.hash)
    }

    @Test("Two unrelated long strings produce different hashes")
    func unrelatedLongStringsHaveDifferentHashes() {
        let a = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
        let b = "The quick brown fox jumps over the lazy dog. Pack my box with five dozen liquor jugs. How vexingly quick daft zebras jump!"
        #expect(a != b)
        #expect(a.hash != b.hash)
    }

    @Test("Long strings differing only in an unsampled region collide")
    func longStringsCollideWhenDifferencesAreUnsampled() {
        let a = makeSampledTwin(length: 200, fillerForUnsampled: "x")
        let b = makeSampledTwin(length: 200, fillerForUnsampled: "y")

        #expect(a != b)
        #expect(a.hash == b.hash)
    }

    @Test("Long strings with completely different unsampled content still collide")
    func unrelatedLookingLongStringsCollideViaSampling() {
        let head = String(repeating: "A", count: 32)
        let middle = String(repeating: "M", count: 32)
        let tail = String(repeating: "Z", count: 32)
        let s1 = head
            + String(repeating: "1", count: 52)
            + middle
            + String(repeating: "2", count: 52)
            + tail
        let s2 = head
            + "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
            + middle
            + "zyxwvutsrqponmlkjihgfedcbaZYXWVUTSRQPONMLKJIHGFEDCBA"
            + tail

        #expect(s1 != s2)
        #expect(s1.hash == s2.hash)
    }

    @Test("Long strings differing inside a sampled region produce different hashes")
    func longStringsDifferingInSampledRegionDiffer() {
        let base = String(repeating: "A", count: 200)
        var copy = Array(base)
        copy[0] = "B" // index 0 lands in the first sampled window
        let modified = String(copy)

        #expect(base != modified)
        #expect(base.hash != modified.hash)
    }

    @Test("SHA-256 of the same input is the same on every call")
    func sha256IsDeterministicForSameInput() {
        let input = "OGM3ZjRkYjctYjE0Mi00MWU4LWIwYWQtMWI5YmYzZmVjZGE0OnM0bFRpSTc1QjNYXzl3Y29NeXdOS0RjRi16cW1oUFM3VFEtU2NUbzlSVlU"
        let h1 = sha256Hex(input)
        let h2 = sha256Hex(input)
        let h3 = sha256Hex(input)
        #expect(h1 == h2)
        #expect(h2 == h3)
    }

    @Test("Pairs that collide under .hash produce distinct SHA-256 digests")
    func sha256DistinguishesHashCollisionPairs() {
        let a = makeSampledTwin(length: 200, fillerForUnsampled: "x")
        let b = makeSampledTwin(length: 200, fillerForUnsampled: "y")

        #expect(a.hash == b.hash) // baseline: collide under .hash
        #expect(sha256Hex(a) != sha256Hex(b))
    }

    /// Returns a string whose three NSString.hash sampling windows hold the
    /// same content across calls, varying only in the unsampled gaps.
    private func makeSampledTwin(length: Int, fillerForUnsampled: Character) -> String {
        var chars = [Character](repeating: fillerForUnsampled, count: length)
        let head = String(repeating: "A", count: 32)
        let middle = String(repeating: "M", count: 32)
        let tail = String(repeating: "Z", count: 32)
        for (i, c) in head.enumerated() {
            chars[i] = c
        }
        for (i, c) in middle.enumerated() {
            chars[length / 2 - 16 + i] = c
        }
        for (i, c) in tail.enumerated() {
            chars[length - 32 + i] = c
        }
        return String(chars)
    }

    /// SHA-256 of the UTF-8 bytes, lowercase hex. Byte-identical to the
    /// `CryptoSwift.String.sha256()` call used in `TangemPayAuthorizationAPITarget`.
    private func sha256Hex(_ string: String) -> String {
        SHA256.hash(data: Data(string.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}
