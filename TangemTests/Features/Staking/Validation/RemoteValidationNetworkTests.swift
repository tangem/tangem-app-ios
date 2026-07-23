//
//  RemoteValidationNetworkTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
@testable import Tangem
@testable import BlockchainSdk

@Suite("RemoteValidationNetwork Tests")
struct RemoteValidationNetworkTests {
    @Test(arguments: evmBlockchains)
    func evmBlockchainMapsToEvm(blockchain: Blockchain) {
        let network = RemoteValidationNetwork(blockchain: blockchain)
        if case .evm(let mappedBlockchain) = network {
            #expect(mappedBlockchain == blockchain)
        } else {
            Issue.record("Expected .evm case for \(blockchain)")
        }
    }

    @Test
    func solanaMapsToSolana() {
        let network = RemoteValidationNetwork(blockchain: solanaBlockchain)
        guard case .solana = network else {
            Issue.record("Expected .solana case")
            return
        }
    }

    @Test(arguments: unsupportedBlockchains)
    func unsupportedBlockchainReturnsNil(blockchain: Blockchain) {
        let network = RemoteValidationNetwork(blockchain: blockchain)
        #expect(network == nil)
    }
}

// MARK: - Test Data

private extension RemoteValidationNetworkTests {
    static let evmBlockchains: [Blockchain] = [
        .bsc(testnet: false),
        .ethereum(testnet: false),
    ]

    var solanaBlockchain: Blockchain { .solana(curve: .ed25519, testnet: false) }

    static let unsupportedBlockchains: [Blockchain] = [
        .bitcoin(testnet: false),
        .polygon(testnet: false),
        .tron(testnet: false),
        .cardano(extended: false),
    ]
}
