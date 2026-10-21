//
//  CommonCollectiblesColdOwnerProviderTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Foundation
import TangemCollectibles
import TangemSdk
import TangemTestKit
import Testing
@testable import Tangem

@Suite("CommonCollectiblesColdOwnerProvider")
final class CommonCollectiblesColdOwnerProviderTests: LeakTrackingTestSuite {
    typealias SUT = CommonCollectiblesColdOwnerProvider

    @Test("Builds the cold owner from the key derived at the account path")
    func buildsColdOwnerFromHeldDerivation() {
        let sut = makeSUT(keys: [Constants.key(seed: Constants.ed25519Seed, curve: .ed25519, derivedAt: Constants.path)])

        let expected = Wallet.PublicKey(
            seedKey: Constants.ed25519Seed,
            derivationType: .plain(.init(path: Constants.path, extendedPublicKey: Constants.extendedPublicKey))
        )
        #expect(sut.coldOwnerKey() == expected)
    }

    @Test("Reads the key of the curve the derivation style dictates", arguments: Self.curveArguments)
    func picksSeedKeyByDerivationStyle(derivationStyle: DerivationStyle?, seedKey: Data) {
        let sut = makeSUT(
            derivationStyle: derivationStyle,
            keys: [
                Constants.key(seed: Constants.ed25519Seed, curve: .ed25519, derivedAt: Constants.path),
                Constants.key(seed: Constants.slip0010Seed, curve: .ed25519_slip0010, derivedAt: Constants.path),
            ]
        )

        #expect(sut.coldOwnerKey()?.seedKey == seedKey)
    }

    @Test("A key not yet derived at the account path yields no cold owner")
    func missingDerivationYieldsNil() {
        let sut = makeSUT(keys: [Constants.key(seed: Constants.ed25519Seed, curve: .ed25519, derivedAt: nil)])

        #expect(sut.coldOwnerKey() == nil)
    }

    @Test("A derivation held at another path does not count")
    func otherPathDoesNotCount() throws {
        let otherPath = try DerivationPath(rawPath: "m/44'/501'/0'/0'/0'")
        let sut = makeSUT(keys: [Constants.key(seed: Constants.ed25519Seed, curve: .ed25519, derivedAt: otherPath)])

        #expect(sut.coldOwnerKey() == nil)
    }

    @Test("A wallet without a master key of the needed curve yields no cold owner")
    func missingMasterKeyYieldsNil() {
        let sut = makeSUT(keys: [Constants.key(seed: Constants.slip0010Seed, curve: .ed25519_slip0010, derivedAt: Constants.path)])

        #expect(sut.coldOwnerKey() == nil)
    }
}

// MARK: - Arguments

extension CommonCollectiblesColdOwnerProviderTests {
    nonisolated static let curveArguments: [(derivationStyle: DerivationStyle?, seedKey: Data)] = [
        (derivationStyle: nil, seedKey: Constants.ed25519Seed),
        (derivationStyle: .v1, seedKey: Constants.ed25519Seed),
        (derivationStyle: .v2, seedKey: Constants.ed25519Seed),
        (derivationStyle: .v3, seedKey: Constants.slip0010Seed),
    ]
}

// MARK: - Helpers

private extension CommonCollectiblesColdOwnerProviderTests {
    enum Constants {
        static let path = CollectiblesAccountKeyPath.derivationPath
        static let ed25519Seed = Data(repeating: 0x11, count: 32)
        static let slip0010Seed = Data(repeating: 0x22, count: 32)
        static let chainCode = Data(repeating: 0x33, count: 32)
        static let extendedPublicKey = ExtendedPublicKey(publicKey: Data(repeating: 0x44, count: 32), chainCode: chainCode)

        static func key(seed: Data, curve: EllipticCurve, derivedAt path: DerivationPath?) -> KeyInfo {
            KeyInfo(
                publicKey: seed,
                chainCode: chainCode,
                curve: curve,
                isImported: false,
                derivedKeys: path.map { [$0: extendedPublicKey] } ?? [:]
            )
        }
    }

    func makeSUT(derivationStyle: DerivationStyle? = nil, keys: [KeyInfo]) -> SUT {
        trackForMemoryLeaks(SUT(keysRepository: KeysRepositoryTestsMock(keys: keys), derivationStyle: derivationStyle))
    }
}
