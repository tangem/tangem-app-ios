//
//  SupportedNetworkTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem
@testable import BlockchainSdk

/// Remote (BlockAid) network mapping is covered by `RemoteValidationNetworkTests`.
@Suite("LocalStakingSupportedNetwork Tests")
struct SupportedNetworkTests {
    @Test(arguments: localSupportedMappings)
    func localSupportedBlockchainMapsCorrectly(
        blockchain: Blockchain,
        expectedNetwork: LocalStakingSupportedNetwork
    ) {
        let network = LocalStakingSupportedNetwork(blockchain: blockchain)
        #expect(network == expectedNetwork)
    }

    @Test(arguments: localUnsupportedBlockchains)
    func localUnsupportedBlockchainReturnsNil(blockchain: Blockchain) {
        let network = LocalStakingSupportedNetwork(blockchain: blockchain)
        #expect(network == nil)
    }

    @Test
    func everySupportedNetworkHasAMapping() {
        let mapped = Set(Self.localSupportedMappings.map(\.1))
        #expect(mapped == Set(LocalStakingSupportedNetwork.allCases))
    }
}

// MARK: - Test Data

private extension SupportedNetworkTests {
    static let localSupportedMappings: [(Blockchain, LocalStakingSupportedNetwork)] = [
        (.tron(testnet: false), .tron),
        (.solana(curve: .ed25519, testnet: false), .solana),
        (.cosmos(testnet: false), .cosmos),
        (.bsc(testnet: false), .bsc),
        (.cardano(extended: false), .cardano),
    ]

    static let localUnsupportedBlockchains: [Blockchain] = [
        .ethereum(testnet: false),
        .bitcoin(testnet: false),
        .polygon(testnet: false),
    ]
}
