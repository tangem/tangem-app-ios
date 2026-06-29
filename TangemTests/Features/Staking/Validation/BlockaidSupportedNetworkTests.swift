//
//  BlockaidSupportedNetworkTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
@testable import Tangem
@testable import BlockchainSdk

@Suite("BlockaidSupportedNetwork Tests")
struct BlockaidSupportedNetworkTests {
    @Test(arguments: evmBlockchains)
    func evmBlockchainMapsToEvm(blockchain: Blockchain) {
        let network = BlockaidSupportedNetwork(blockchain: blockchain)
        if case .evm(let mappedBlockchain) = network {
            #expect(mappedBlockchain == blockchain)
        } else {
            Issue.record("Expected .evm case for \(blockchain)")
        }
    }

    @Test
    func solanaMapsToSolana() {
        let network = BlockaidSupportedNetwork(blockchain: solanaBlockchain)
        guard case .solana = network else {
            Issue.record("Expected .solana case")
            return
        }
    }

    @Test(arguments: unsupportedBlockchains)
    func unsupportedBlockchainReturnsNil(blockchain: Blockchain) {
        let network = BlockaidSupportedNetwork(blockchain: blockchain)
        #expect(network == nil)
    }
}

// MARK: - Test Data

private extension BlockaidSupportedNetworkTests {
    static let evmBlockchains: [Blockchain] = [
        .ethereum(testnet: false),
        .bsc(testnet: false),
    ]

    var solanaBlockchain: Blockchain { .solana(curve: .ed25519, testnet: false) }

    static let unsupportedBlockchains: [Blockchain] = [
        .bitcoin(testnet: false),
        .polygon(testnet: false),
        .tron(testnet: false),
        .cardano(extended: false),
    ]
}
