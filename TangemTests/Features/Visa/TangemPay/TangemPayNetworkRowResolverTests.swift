//
//  TangemPayNetworkRowResolverTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
import BlockchainSdk
@testable import Tangem

@Suite("TangemPay network rows")
struct TangemPayNetworkRowResolverTests {
    @Test("An EVM network the name table doesn't list still gets a row — the withdraw side resolves it too")
    func unlistedEVMNetworkResolvesByChainId() throws {
        let networks = try makeTangemPayNetworks(Self.optimismPayload)

        let rows = TangemPayNetworkRowResolver.resolve(networks)

        #expect(rows.map(\.title) == [Blockchain.optimism(testnet: false).displayName])
        #expect(rows.map(\.id) == [10])
    }

    @Test("The receive sheet opens on such a network too — its deposit address is as real as any")
    func unlistedEVMNetworkHasReceiveInput() throws {
        let network = try #require(makeTangemPayNetworks(Self.optimismPayload).first)

        let input = TangemPayNetworkRowResolver.receiveInput(for: network, depositAddress: "0xdeposit")

        #expect(input?.blockchain == .optimism(testnet: false))
    }

    @Test("A network with neither a known name nor an EVM chain id has nothing to show")
    func unaddressableNetworkHasNoRow() throws {
        let networks = try makeTangemPayNetworks(
            """
            [
              {
                "name": "\(Blockchain.solana(curve: .ed25519_slip0010, testnet: false).networkId)",
                "isTestnet": false,
                "chainId": 0,
                "status": "ENABLED",
                "depositAddress": "solanadeposit",
                "tokens": [{ "token": "USDC", "tokenContractAddress": "SoLusdc" }]
              }
            ]
            """
        )

        #expect(TangemPayNetworkRowResolver.resolve(networks).isEmpty)
    }

    @Test("The receive sheet lists USDC before USDT whatever order the backend sends")
    func receiveInputListsUSDCFirst() throws {
        let network = try #require(makeTangemPayNetworks(Self.polygonPayload(status: "ENABLED")).first)

        let input = TangemPayNetworkRowResolver.receiveInput(for: network, depositAddress: "0xdeposit")

        #expect(input?.tokens.map(\.symbol) == ["USDC", "USDT"])
    }

    @Test("An enabled network's row lists USDC before USDT whatever order the backend sends")
    func enabledRowSubtitleListsUSDCFirst() throws {
        let networks = try makeTangemPayNetworks(Self.polygonPayload(status: "ENABLED"))

        #expect(TangemPayNetworkRowResolver.resolve(networks).map(\.subtitle) == ["USDC, USDT"])
    }

    @Test("A network without a contract yet lists USDC before USDT")
    func notIssuedRowSubtitleListsUSDCFirst() throws {
        let networks = try makeTangemPayNetworks(Self.polygonPayload(status: "NOT_ISSUED"))

        #expect(TangemPayNetworkRowResolver.resolve(networks).map(\.subtitle) == ["USDC, USDT"])
    }

    private static func polygonPayload(status: String) -> String {
        """
        [
          {
            "name": "polygon",
            "isTestnet": false,
            "chainId": 137,
            "status": "\(status)",
            "depositAddress": "0xdeposit",
            "tokens": [
              { "token": "USDT", "tokenContractAddress": "0xpolygonusdt" },
              { "token": "USDC", "tokenContractAddress": "0xpolygonusdc" }
            ]
          }
        ]
        """
    }

    private static let optimismPayload = """
    [
      {
        "name": "op-mainnet",
        "isTestnet": false,
        "chainId": 10,
        "status": "ENABLED",
        "depositAddress": "0xdeposit",
        "tokens": [{ "token": "USDC", "tokenContractAddress": "0xopusdc" }]
      }
    ]
    """
}
