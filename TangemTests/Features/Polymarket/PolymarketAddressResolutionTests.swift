//
//  PolymarketAddressResolutionTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemPolymarket
import TangemSdk
@testable import Tangem

@Suite
struct PolymarketAddressResolutionTests {
    private static let derivedPublicKey = Data(hexString: "0241DCD64B5F4A039FC339A16300A833A883B218909F2EBCAF3906651C76842C45")
    private static let derivedAddress = "0x6ECa00c52AFC728CDbF42E817d712e175bb23C7d"

    private static let walletPublicKey = Data(hexString: "0279BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798")
    private static let chainCode = Data(repeating: 0x11, count: 32)

    private static let foreignPath = try! DerivationPath(rawPath: "m/44'/60'/0'/0/0")

    @Test
    func theAddressIsBuiltFromTheDerivedKeyNotTheWalletKey() throws {
        let ownerKey = PolymarketUtilities.makePublicKey(seedKey: Self.walletPublicKey, derivedKey: Self.makeExtendedPublicKey(Self.derivedPublicKey))
        let swapped = PolymarketUtilities.makePublicKey(seedKey: Self.derivedPublicKey, derivedKey: Self.makeExtendedPublicKey(Self.walletPublicKey))

        #expect(try PolymarketUtilities.makeAddress(using: ownerKey) == Self.derivedAddress)
        #expect(try PolymarketUtilities.makeAddress(using: swapped) != Self.derivedAddress)
    }

    @Test
    func theStoredKeyIsReadFromTheOwnerPathOnly() {
        let repository = Self.makeRepository(curve: .secp256k1, path: Self.foreignPath)

        #expect(PolymarketUtilities.getKey(from: repository) == nil)
    }

    @Test
    func aKeyOnAnotherCurveIsNeverUsed() {
        let repository = Self.makeRepository(curve: .ed25519, path: PolymarketUtilities.derivationPath)

        #expect(PolymarketUtilities.getKey(from: repository) == nil)
    }

    @Test
    func theStoredKeyResolvesToTheOwnerAddress() throws {
        let repository = Self.makeRepository(curve: .secp256k1, path: PolymarketUtilities.derivationPath)
        let ownerKey = try #require(PolymarketUtilities.getKey(from: repository))

        #expect(try PolymarketUtilities.makeAddress(using: ownerKey) == Self.derivedAddress)
    }
}

// MARK: - Fixtures

private extension PolymarketAddressResolutionTests {
    static func makeExtendedPublicKey(_ publicKey: Data) -> ExtendedPublicKey {
        ExtendedPublicKey(publicKey: publicKey, chainCode: chainCode)
    }

    static func makeKeyInfo(curve: EllipticCurve, derivedKey: ExtendedPublicKey, path: DerivationPath) -> KeyInfo {
        KeyInfo(
            publicKey: walletPublicKey,
            chainCode: chainCode,
            curve: curve,
            isImported: false,
            derivedKeys: [path: derivedKey]
        )
    }

    static func makeRepository(curve: EllipticCurve, path: DerivationPath) -> KeysRepositoryTestsMock {
        KeysRepositoryTestsMock(keys: [makeKeyInfo(curve: curve, derivedKey: makeExtendedPublicKey(derivedPublicKey), path: path)])
    }
}
