//
//  CollectiblesAccountKeyPathBlockchainNetworkTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Foundation
import TangemCollectibles
import TangemSdk
import Testing
@testable import Tangem

@Suite("CollectiblesAccountKeyPath.blockchainNetwork")
struct CollectiblesAccountKeyPathBlockchainNetworkTests {
    @Test("Asks to derive the Packs key on the master key the cold owner is read from", arguments: Self.curveArguments)
    func pendsPacksKeyOnColdOwnerCurve(derivationStyle: DerivationStyle?, seedKey: Data) {
        let network = CollectiblesAccountKeyPath.blockchainNetwork(for: derivationStyle)
        let keys = [
            Constants.masterKey(seed: Constants.ed25519Seed, curve: .ed25519),
            Constants.masterKey(seed: Constants.slip0010Seed, curve: .ed25519_slip0010),
        ]

        let pendingDerivations = PendingDerivationHelper.pendingDerivations(network: network, keys: keys)
        let masterKeys = pendingDerivations.map(\.masterKey.publicKey)
        let paths = pendingDerivations.flatMap(\.paths)

        #expect(masterKeys == [seedKey])
        #expect(paths == [CollectiblesAccountKeyPath.derivationPath])
    }
}

// MARK: - Arguments

extension CollectiblesAccountKeyPathBlockchainNetworkTests {
    static let curveArguments: [(derivationStyle: DerivationStyle?, seedKey: Data)] = [
        (derivationStyle: nil, seedKey: Constants.ed25519Seed),
        (derivationStyle: .v1, seedKey: Constants.ed25519Seed),
        (derivationStyle: .v2, seedKey: Constants.ed25519Seed),
        (derivationStyle: .v3, seedKey: Constants.slip0010Seed),
    ]
}

// MARK: - Helpers

private extension CollectiblesAccountKeyPathBlockchainNetworkTests {
    enum Constants {
        static let ed25519Seed = Data(repeating: 0x11, count: 32)
        static let slip0010Seed = Data(repeating: 0x22, count: 32)

        static func masterKey(seed: Data, curve: EllipticCurve) -> KeyInfo {
            KeyInfo(
                publicKey: seed,
                chainCode: Data(repeating: 0x33, count: 32),
                curve: curve,
                isImported: false,
                derivedKeys: [:]
            )
        }
    }
}
