//
//  PolkadotGenesisHashTests.swift
//  BlockchainSdkTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import Testing
@testable import BlockchainSdk

struct PolkadotGenesisHashTests {
    private let mainnets: [PolkadotNetwork] = [
        .polkadot(curve: .ed25519),
        .kusama(curve: .ed25519),
        .azero(curve: .ed25519, testnet: false),
        .joystream(curve: .ed25519),
        .bittensor(curve: .ed25519),
        .energyWebX(curve: .ed25519),
    ]

    @Test
    func everyMainnetPinsA32ByteGenesisHash() throws {
        for network in mainnets {
            let pinned = try #require(network.genesisHash, "\(network.blockchainName) must pin its genesis hash")
            #expect(pinned.hasPrefix("0x"))
            #expect(Data(hexString: pinned).count == 32, "\(network.blockchainName) genesis hash is not 32 bytes")
        }
    }

    @Test
    func pinnedGenesisHashesAreDistinctAcrossNetworks() {
        let hashes = mainnets.compactMap(\.genesisHash).map { $0.lowercased() }
        #expect(Set(hashes).count == hashes.count, "two networks share a genesis hash")
    }

    @Test
    func polkadotAndKusamaMatchTheKnownValues() {
        // @polkadot/networks `knownGenesis`
        #expect(PolkadotNetwork.polkadot(curve: .ed25519).genesisHash == "0x91b171bb158e2d3848fa23a9f1c25182fb8e20313b2c1eb49219da7a70ce90c3")
        #expect(PolkadotNetwork.kusama(curve: .ed25519).genesisHash == "0xb0a8d493285c2df73290dfb7e61f870f17b41801197a149ca93654499ea3dafe")
    }

    @Test
    func genesisHashComparisonIgnoresCaseAndPrefix() {
        let expected = "0x91b171bb158e2d3848fa23a9f1c25182fb8e20313b2c1eb49219da7a70ce90c3"

        #expect(PolkadotNetworkService.genesisHashMatches(expected, expected: expected))
        #expect(PolkadotNetworkService.genesisHashMatches(expected.uppercased(), expected: expected))
        #expect(PolkadotNetworkService.genesisHashMatches(String(expected.dropFirst(2)), expected: expected))

        // A Kusama genesis returned by a "Polkadot" node must be rejected.
        let kusama = "0xb0a8d493285c2df73290dfb7e61f870f17b41801197a149ca93654499ea3dafe"
        #expect(!PolkadotNetworkService.genesisHashMatches(kusama, expected: expected))
        #expect(!PolkadotNetworkService.genesisHashMatches("", expected: expected))
    }
}
