//
//  TangemPayAccountTokensResolverTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import BlockchainSdk
import TangemPay
@testable import Tangem

@Suite("TangemPayAccountTokensResolver entries")
struct TangemPayAccountTokensResolverTests {
    @Test("An issued network contributes one entry per token")
    func issuedNetworkTokens() throws {
        let networks = try makeNetworks(
            """
            [
              {
                "name": "\(Blockchain.polygon(testnet: false).networkId)",
                "isTestnet": false,
                "chainId": 137,
                "status": "ENABLED",
                "depositAddress": "0xdeposit",
                "tokens": [
                  { "token": "USDC", "tokenContractAddress": "0xusdc", "availableForWithdrawal": 12.5 },
                  { "token": "USDT", "tokenContractAddress": "0xusdt" }
                ]
              }
            ]
            """
        )

        let entries = TangemPayAccountTokensResolver.makeEntries(from: networks)

        #expect(entries.count == 2)
        #expect(entries.allSatisfy { $0.blockchain == .polygon(testnet: false) })
        #expect(entries.allSatisfy { $0.depositAddress == "0xdeposit" })
        #expect(entries.map(\.contractAddress) == ["0xusdc", "0xusdt"])
        #expect(entries.map(\.availableForWithdrawal) == [12.5, nil])
    }

    @Test("A network whose contract is not issued yet is skipped — destinations are picked automatically")
    func notIssuedNetworkSkipped() throws {
        let networks = try makeNetworks(
            """
            [
              {
                "name": "\(Blockchain.base(testnet: false).networkId)",
                "isTestnet": false,
                "chainId": 8453,
                "status": "NOT_ISSUED",
                "depositAddress": "0xdeposit",
                "tokens": [{ "token": "USDC", "tokenContractAddress": "0xusdc" }]
              }
            ]
            """
        )

        #expect(TangemPayAccountTokensResolver.makeEntries(from: networks).isEmpty)
    }

    @Test("Disabled and unknown-status networks are skipped")
    func nonEnabledStatusesSkipped() throws {
        let networks = try makeNetworks(
            """
            [
              {
                "name": "\(Blockchain.bsc(testnet: false).networkId)",
                "isTestnet": false,
                "chainId": 56,
                "status": "DISABLED",
                "depositAddress": "0xdeposit",
                "tokens": [{ "token": "USDC", "tokenContractAddress": "0xusdc" }]
              },
              {
                "name": "\(Blockchain.arbitrum(testnet: false).networkId)",
                "isTestnet": false,
                "chainId": 42161,
                "status": "SOMETHING_NEW",
                "depositAddress": "0xdeposit",
                "tokens": [{ "token": "USDC", "tokenContractAddress": "0xusdc" }]
              }
            ]
            """
        )

        #expect(TangemPayAccountTokensResolver.makeEntries(from: networks).isEmpty)
    }

    @Test("A network without a deposit address is skipped")
    func missingDepositAddressSkipped() throws {
        let networks = try makeNetworks(
            """
            [
              {
                "name": "\(Blockchain.ethereum(testnet: false).networkId)",
                "isTestnet": false,
                "chainId": 1,
                "status": "ENABLED",
                "tokens": [{ "token": "USDC", "tokenContractAddress": "0xusdc" }]
              },
              {
                "name": "\(Blockchain.tron(testnet: false).networkId)",
                "isTestnet": false,
                "chainId": 728126428,
                "status": "ENABLED",
                "depositAddress": "",
                "tokens": [{ "token": "USDT", "tokenContractAddress": "TUsdt" }]
              }
            ]
            """
        )

        #expect(TangemPayAccountTokensResolver.makeEntries(from: networks).isEmpty)
    }

    @Test("A network the wallet doesn't support is skipped")
    func unsupportedNetworkSkipped() throws {
        let networks = try makeNetworks(
            """
            [
              {
                "name": "\(Blockchain.avalanche(testnet: false).networkId)",
                "isTestnet": false,
                "chainId": 43114,
                "status": "ENABLED",
                "depositAddress": "0xdeposit",
                "tokens": [{ "token": "USDC", "tokenContractAddress": "0xusdc" }]
              }
            ]
            """
        )

        #expect(TangemPayAccountTokensResolver.makeEntries(from: networks).isEmpty)
    }

    @Test("A coins API failure degrades to the canonical USDC entry instead of an empty account")
    func coinsFailureKeepsCanonicalUSDC() async throws {
        // The checksummed USDC contract differs from the hardcoded lowercase one only in casing.
        let networks = try makeNetworks(
            """
            [
              {
                "name": "\(Blockchain.polygon(testnet: false).networkId)",
                "isTestnet": false,
                "chainId": 137,
                "status": "ENABLED",
                "depositAddress": "0xdeposit",
                "tokens": [
                  { "token": "USDC", "tokenContractAddress": "0x3C499c542cEF5E3811e1192ce70d8cC03d5c3359", "availableForWithdrawal": 12.5 },
                  { "token": "USDT", "tokenContractAddress": "0xusdt", "availableForWithdrawal": 500 }
                ]
              }
            ]
            """
        )

        let service = FakeTangemApiService()
        service.loadCoinsHandler = { _ in throw "coins API is down" }

        let tokens = await withInjectedTangemApiService(service) {
            await TangemPayAccountTokensResolver().resolve(networks: networks)
        }

        #expect(tokens.map(\.tokenItem) == [TangemPayUtilities.usdcTokenItem])
        #expect(tokens.first?.depositAddress == "0xdeposit")
        #expect(tokens.first?.availableForWithdrawal == 12.5)
    }

    @Test("The canonical entry keeps the hardcoded token item even when the catalog also knows it")
    func canonicalEntryPrefersHardcodedTokenItem() async throws {
        let networks = try makeNetworks(
            """
            [
              {
                "name": "\(Blockchain.polygon(testnet: false).networkId)",
                "isTestnet": false,
                "chainId": 137,
                "status": "ENABLED",
                "depositAddress": "0xdeposit",
                "tokens": [
                  { "token": "USDC", "tokenContractAddress": "0x3C499c542cEF5E3811e1192ce70d8cC03d5c3359", "availableForWithdrawal": 12.5 }
                ]
              }
            ]
            """
        )

        let service = FakeTangemApiService()
        service.loadCoinsHandler = { _ in
            CoinsList.Response(
                total: 1,
                imageHost: nil,
                coins: [
                    CoinsList.Coin(
                        id: "usd-coin",
                        name: "USD Coin",
                        symbol: "USDC",
                        networks: [
                            NetworkModel(
                                networkId: Blockchain.polygon(testnet: false).networkId,
                                contractAddress: "0x3c499c542cef5e3811e1192ce70d8cc03d5c3359",
                                decimalCount: 6
                            ),
                        ]
                    ),
                ]
            )
        }

        let tokens = await withInjectedTangemApiService(service) {
            await TangemPayAccountTokensResolver().resolve(networks: networks)
        }

        // The Pay screen matches pending swaps by the full hardcoded item (with its derivation);
        // a catalog copy without one would unhook them.
        #expect(tokens.map(\.tokenItem) == [TangemPayUtilities.usdcTokenItem])
    }

    @Test("A live coins API resolves a checksummed BFF contract against its lowercase catalog entry")
    func checksummedContractResolvesAgainstLowercaseCatalog() async throws {
        let networks = try makeNetworks(
            """
            [
              {
                "name": "\(Blockchain.polygon(testnet: false).networkId)",
                "isTestnet": false,
                "chainId": 137,
                "status": "ENABLED",
                "depositAddress": "0xdeposit",
                "tokens": [
                  { "token": "USDT", "tokenContractAddress": "\(Self.usdtContract)", "availableForWithdrawal": 42 }
                ]
              }
            ]
            """
        )

        let tokens = await withInjectedTangemApiService(makeUSDTCatalogService()) {
            await TangemPayAccountTokensResolver().resolve(networks: networks)
        }

        #expect(tokens.count == 1)
        #expect(tokens.first?.tokenItem.token?.symbol == "USDT")
        #expect(tokens.first?.tokenItem.decimalCount == 6)
        #expect(tokens.first?.availableForWithdrawal == 42)
    }

    @Test("A token the live coins API doesn't know is dropped, resolved neighbors survive")
    func unresolvedTokenDroppedWhileAPIIsAlive() async throws {
        let networks = try makeNetworks(
            """
            [
              {
                "name": "\(Blockchain.polygon(testnet: false).networkId)",
                "isTestnet": false,
                "chainId": 137,
                "status": "ENABLED",
                "depositAddress": "0xdeposit",
                "tokens": [
                  { "token": "USDT", "tokenContractAddress": "\(Self.usdtContract)" },
                  { "token": "FOO", "tokenContractAddress": "0xunknown" }
                ]
              }
            ]
            """
        )

        let tokens = await withInjectedTangemApiService(makeUSDTCatalogService()) {
            await TangemPayAccountTokensResolver().resolve(networks: networks)
        }

        #expect(tokens.map { $0.tokenItem.token?.symbol } == ["USDT"])
    }

    /// Not the canonical USDC — its fallback would mask a broken lookup.
    private static let usdtContract = "0xc2132D05D31c914a87C6611C10748AEb04B58e8F"

    /// The coins API stores contracts lowercased, unlike the BFF's checksummed ones.
    private func makeUSDTCatalogService() -> FakeTangemApiService {
        let service = FakeTangemApiService()
        service.loadCoinsHandler = { _ in
            CoinsList.Response(
                total: 1,
                imageHost: nil,
                coins: [
                    CoinsList.Coin(
                        id: "tether",
                        name: "Tether",
                        symbol: "USDT",
                        networks: [
                            NetworkModel(
                                networkId: Blockchain.polygon(testnet: false).networkId,
                                contractAddress: Self.usdtContract.lowercased(),
                                decimalCount: 6
                            ),
                        ]
                    ),
                ]
            )
        }
        return service
    }

    private func makeNetworks(_ json: String) throws -> [TangemPayBalance.Network] {
        let balanceJSON = """
        {
          "fiat": {
            "currency": "USD",
            "availableBalance": 0,
            "creditLimit": 0,
            "pendingCharges": 0,
            "postedCharges": 0,
            "balanceDue": 0
          },
          "crypto": {
            "id": "usd-coin",
            "chainId": 137,
            "depositAddress": "0xdeposit",
            "tokenContractAddress": "0xusdc",
            "balance": 0
          },
          "availableForWithdrawal": { "amount": 0, "currency": "USD" },
          "networks": \(json)
        }
        """

        let balance = try JSONDecoder().decode(TangemPayBalance.self, from: Data(balanceJSON.utf8))
        return balance.networks
    }
}
