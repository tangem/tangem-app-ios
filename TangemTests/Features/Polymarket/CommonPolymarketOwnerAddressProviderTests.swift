//
//  CommonPolymarketOwnerAddressProviderTests.swift
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
struct CommonPolymarketOwnerAddressProviderTests {
    private static let derivedPublicKey = Data(hexString: "0241DCD64B5F4A039FC339A16300A833A883B218909F2EBCAF3906651C76842C45")
    private static let derivedAddress = "0x6ECa00c52AFC728CDbF42E817d712e175bb23C7d"

    private static let walletPublicKey = Data(hexString: "0279BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798")
    private static let chainCode = Data(repeating: 0x11, count: 32)

    @Test
    func anAlreadyDerivedKeyResolvesTheOwnerAddress() {
        let provider = CommonPolymarketOwnerAddressProvider(
            keysRepository: Self.makeRepository(derivedKey: Self.extendedPublicKey)
        )

        #expect(provider.getOwnerAddress() == Self.derivedAddress)
    }

    @Test
    func aKeyThatWasNeverDerivedHasNoOwnerAddress() {
        let provider = CommonPolymarketOwnerAddressProvider(keysRepository: Self.makeRepository(derivedKey: nil))

        #expect(provider.getOwnerAddress() == nil)
    }

    @Test
    func aWalletWithoutSecp256k1HasNoOwnerAddress() {
        let repository = KeysRepositoryTestsMock(keys: [Self.makeKeyInfo(curve: .ed25519, derivedKey: Self.extendedPublicKey)])
        let provider = CommonPolymarketOwnerAddressProvider(keysRepository: repository)

        #expect(provider.getOwnerAddress() == nil)
    }
}

// MARK: - Fixtures

private extension CommonPolymarketOwnerAddressProviderTests {
    static var extendedPublicKey: ExtendedPublicKey {
        ExtendedPublicKey(publicKey: derivedPublicKey, chainCode: chainCode)
    }

    static func makeRepository(derivedKey: ExtendedPublicKey?) -> KeysRepositoryTestsMock {
        KeysRepositoryTestsMock(keys: [makeKeyInfo(curve: .secp256k1, derivedKey: derivedKey)])
    }

    static func makeKeyInfo(curve: EllipticCurve, derivedKey: ExtendedPublicKey?) -> KeyInfo {
        KeyInfo(
            publicKey: walletPublicKey,
            chainCode: chainCode,
            curve: curve,
            isImported: false,
            derivedKeys: derivedKey.map { [PolymarketUtilities.derivationPath: $0] } ?? [:]
        )
    }
}
