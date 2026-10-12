//
//  SafeAddressUtilsTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import CryptoSwift
import Testing
import TangemFoundation
@testable import BlockchainSdk

/// Vectors produced by the backend and cross-checked against `predictSafeAddress` of `@safe-global/protocol-kit` on a
/// live node. The very same values are pinned on Android, which is what makes the two platforms agree on the address
/// rather than each merely agree with itself.
///
/// The owners are joint owner keys (`m/44'/60'/888888'/0/{index}`) of the standard test mnemonic
/// "test test test test test test test test test test test junk". Their mixed case is deliberate: a case-sensitive
/// sort reorders them, since 'B' (0x42) sorts ahead of 'a' (0x61) while 'b' sorts after it.
///
/// A failing vector names the step that broke:
/// - `0x4C3C6b28…` / `0xB6097024…` / `0xCdd466ce…` / `0xFa05Fd83…` — the owners were sorted before being lowercased;
/// - `0x908003D4…` (3-of-5) — the owners were not sorted at all;
/// - the address from the other singleton's row — the singletons are mixed up.
@Suite("Tests for the counterfactual Safe address of an owner composition")
struct SafeAddressUtilsTests {
    @Test("The address of a composition is the one the backend and the Safe SDK arrive at", arguments: Vector.all)
    func addressMatchesTheVector(vector: Vector) throws {
        let address = try SafeAddressUtils.compute(
            owners: Array(Constants.owners.prefix(vector.membersCount)),
            threshold: vector.threshold,
            singleton: vector.singleton
        )

        #expect(address == vector.expected)
    }

    @Test("The setup call and the salt built from it match the backend's intermediates")
    func initializerMatchesTheBackendIntermediates() {
        let initializer = SafeAddressUtils.initializer(owners: Array(Constants.owners.prefix(2)), threshold: 2)
        let initializerHash = initializer.sha3(.keccak256)
        let salt = (initializerHash + Array(repeating: 0, count: 32)).sha3(.keccak256)

        #expect(initializer.toHexString() == Constants.initializerOfTwoOfTwo)
        #expect(initializerHash.toHexString() == "243e7295bbdb34d1fb79dc8de1012aae3b8272dcfad97252eb1d88b01b68af80")
        #expect(salt.toHexString() == "9218b0c85d8557a14eed0ca93a9abf7f67db02b365524658a80e2fd0c211b307")
    }

    @Test("Neither the order the owners arrive in nor their letter case changes the address")
    func orderAndCaseOfTheOwnersDoNotMatter() throws {
        let shuffled = Constants.owners.reversed().map { $0.uppercased().replacingOccurrences(of: "0X", with: "0x") }

        let shuffledAddress = try SafeAddressUtils.compute(owners: shuffled, threshold: 3, singleton: .safe)
        let address = try SafeAddressUtils.compute(owners: Constants.owners, threshold: 3, singleton: .safe)

        #expect(shuffledAddress == address)
    }

    /// A composition no Safe can be deployed from is turned away before anything is hashed: each of these would
    /// otherwise produce a well-formed address that is not the account's.
    @Test("A composition that belongs to no deployable Safe is refused", arguments: RefusedComposition.all)
    func malformedCompositionIsRefused(composition: RefusedComposition) {
        #expect(throws: composition.expected) {
            try SafeAddressUtils.compute(
                owners: composition.owners,
                threshold: composition.threshold,
                singleton: .safe
            )
        }
    }
}

// MARK: - Auxiliary types

extension SafeAddressUtilsTests {
    struct Vector {
        let membersCount: Int
        let threshold: Int
        let singleton: SafeSingleton
        let expected: String

        static let all: [Vector] = [
            Vector(membersCount: 2, threshold: 2, singleton: .safe, expected: "0xe7411b2aB7b76a11ca0E6174697714983fC09Cb2"),
            Vector(membersCount: 2, threshold: 1, singleton: .safe, expected: "0xb8Ec0Febbcee24b2AAB1F04FB8E569b108A51160"),
            Vector(membersCount: 3, threshold: 2, singleton: .safe, expected: "0x9295a5836685C5F5f42242f9B64d23E46F8c259F"),
            Vector(membersCount: 5, threshold: 3, singleton: .safe, expected: "0x735F25C3e27b370a8424A8935B9B08a5569F1145"),
            Vector(membersCount: 5, threshold: 5, singleton: .safe, expected: "0x29502c6147A7aA296253E297F62f603aACb16429"),
            Vector(membersCount: 2, threshold: 2, singleton: .safeL2, expected: "0x01460aBb9BE7084b817849e856F249e4cdD73E84"),
            Vector(membersCount: 2, threshold: 1, singleton: .safeL2, expected: "0x13a6c159fbe94D29Ce337f16D810174BbDfC8368"),
            Vector(membersCount: 3, threshold: 2, singleton: .safeL2, expected: "0x30bE590176A93C6Ef687F3b07421A3624deaf476"),
            Vector(membersCount: 5, threshold: 3, singleton: .safeL2, expected: "0x6691785f8458a46b5f080F610f86c4a5B3B0A86b"),
            Vector(membersCount: 5, threshold: 5, singleton: .safeL2, expected: "0x151bd350ec4dA327a2eF9d711E855614D57F1fb1"),
        ]
    }

    struct RefusedComposition {
        let owners: [String]
        let threshold: Int
        let expected: SafeAddressUtils.ComputationError

        static let all: [RefusedComposition] = [
            RefusedComposition(owners: [], threshold: 1, expected: .noOwners),
            // A nibble short, which `Data(hexString:)` would silently drop
            RefusedComposition(
                owners: [Constants.aNibbleShortOwner],
                threshold: 1,
                expected: .malformedOwnerAddress(Constants.aNibbleShortOwner)
            ),
            RefusedComposition(
                owners: [Constants.aByteLongOwner],
                threshold: 1,
                expected: .malformedOwnerAddress(Constants.aByteLongOwner)
            ),
            RefusedComposition(
                owners: [Constants.unprefixedOwner],
                threshold: 1,
                expected: .malformedOwnerAddress(Constants.unprefixedOwner)
            ),
            RefusedComposition(
                owners: [Constants.nonHexOwner],
                threshold: 1,
                expected: .malformedOwnerAddress(Constants.nonHexOwner)
            ),
            // A Safe whose owners differ by case alone cannot be deployed, and the duplicate stops being visible
            // once the initializer lowercases them
            RefusedComposition(
                owners: [Constants.owners[0], Constants.uppercasedFirstOwner],
                threshold: 2,
                expected: .duplicateOwners
            ),
            RefusedComposition(
                owners: Array(Constants.owners.prefix(2)),
                threshold: 0,
                expected: .thresholdOutOfRange(threshold: 0, ownersCount: 2)
            ),
            RefusedComposition(
                owners: Array(Constants.owners.prefix(2)),
                threshold: 3,
                expected: .thresholdOutOfRange(threshold: 3, ownersCount: 2)
            ),
            // Encoded as a small positive number rather than as two's complement, so it would otherwise pass silently
            RefusedComposition(
                owners: Array(Constants.owners.prefix(2)),
                threshold: -1,
                expected: .thresholdOutOfRange(threshold: -1, ownersCount: 2)
            ),
        ]
    }
}

// MARK: - Constants

private extension SafeAddressUtilsTests {
    enum Constants {
        static let owners = [
            "0xa9936482d7d056d6f843f5C6088Ff0123b796bCC", // m/44'/60'/888888'/0/3
            "0xB8C09e7abE7e0F70f4F4cAf48eED46cc8BfdA120", // .../30
            "0xD048326c01787c475Af00C51eb0221d2557bfEc2", // .../24
            "0xb79e9A68F9cB4549E026c4c8fa7F1b1A548ae1Aa", // .../7
            "0xF29F3B603773b3d5cC91cD77dEDA1E656381C7C1", // .../47
        ]

        static let aNibbleShortOwner = String(owners[0].dropLast())
        static let aByteLongOwner = owners[0] + "00"
        static let unprefixedOwner = owners[0].removeHexPrefix()
        static let nonHexOwner = "0xZZ36482d7d056d6f843f5C6088Ff0123b796bCC1"
        static let uppercasedFirstOwner = owners[0].uppercased().replacingOccurrences(of: "0X", with: "0x")

        static let initializerOfTwoOfTwo = """
        b63e800d\
        0000000000000000000000000000000000000000000000000000000000000100\
        0000000000000000000000000000000000000000000000000000000000000002\
        0000000000000000000000000000000000000000000000000000000000000000\
        0000000000000000000000000000000000000000000000000000000000000160\
        0000000000000000000000003efcbb83a4a7afcb4f68d501e2c2203a38be77f4\
        0000000000000000000000000000000000000000000000000000000000000000\
        0000000000000000000000000000000000000000000000000000000000000000\
        0000000000000000000000000000000000000000000000000000000000000000\
        0000000000000000000000000000000000000000000000000000000000000002\
        000000000000000000000000a9936482d7d056d6f843f5c6088ff0123b796bcc\
        000000000000000000000000b8c09e7abe7e0f70f4f4caf48eed46cc8bfda120\
        0000000000000000000000000000000000000000000000000000000000000000
        """
    }
}
