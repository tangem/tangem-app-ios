//
//  TangemPayAccountTokensResolverTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
import BlockchainSdk
import TangemPay
@testable import Tangem

@Suite("TangemPayAccountTokensResolver entries")
struct TangemPayAccountTokensResolverTests {
    @Test("An issued network contributes one entry per token")
    func issuedNetworkTokens() throws {
        let networks = try makeTangemPayNetworks(
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
        // The withdraw API addresses networks by the BFF's chain id.
        #expect(entries.allSatisfy { $0.chainId == 137 })
    }

    @Test("A network whose contract is not issued yet is skipped — destinations are picked automatically")
    func notIssuedNetworkSkipped() throws {
        let networks = try makeTangemPayNetworks(
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
        let networks = try makeTangemPayNetworks(
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
        let networks = try makeTangemPayNetworks(
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

    @Test("A network neither table can address is skipped — no name, and no EVM chain id either")
    func unaddressableNetworkSkipped() throws {
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

        #expect(TangemPayAccountTokensResolver.makeEntries(from: networks).isEmpty)
    }

    @Test("The canonical entry keeps the hardcoded token item, checksum casing and all")
    func canonicalEntryKeepsHardcodedTokenItem() throws {
        // The checksummed USDC contract differs from the hardcoded lowercase one only in casing.
        let networks = try makeTangemPayNetworks(
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

        let tokens = TangemPayAccountTokensResolver().resolve(networks: networks)

        // The Pay screen matches pending swaps by the full hardcoded item, derivation included.
        #expect(tokens.map(\.tokenItem) == [TangemPayUtilities.usdcTokenItem])
        #expect(tokens.first?.depositAddress == "0xdeposit")
        #expect(tokens.first?.availableForWithdrawal == 12.5)
    }

    @Test("Every other token is built from the balance payload at the account's stable decimals")
    func nonCanonicalTokenBuiltFromBalancePayload() throws {
        let networks = try makeTangemPayNetworks(
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

        let tokens = TangemPayAccountTokensResolver().resolve(networks: networks)

        #expect(tokens.count == 1)
        // The chain id is what the withdraw request addresses the token by.
        #expect(tokens.first?.chainId == 137)
        #expect(tokens.first?.tokenItem.token?.symbol == "USDT")
        #expect(tokens.first?.tokenItem.contractAddress == Self.usdtContract.lowercased())
        #expect(tokens.first?.tokenItem.decimalCount == TangemPayUtilities.Constants.defaultTokenDecimalCount)
        #expect(tokens.first?.availableForWithdrawal == 42)
    }

    @Test("A token no catalog knows still reaches the account — funds sit on it either way")
    func unknownTokenSurvives() throws {
        let networks = try makeTangemPayNetworks(
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

        let tokens = TangemPayAccountTokensResolver().resolve(networks: networks)

        #expect(tokens.map { $0.tokenItem.token?.symbol } == ["USDT", "FOO"])
    }

    @Test("BNB Smart Chain stables are eighteen-decimal — they are Binance-Peg, not native")
    func bscTokensCarryEighteenDecimals() throws {
        let networks = try makeTangemPayNetworks(
            """
            [
              {
                "name": "\(Blockchain.bsc(testnet: false).networkId)",
                "isTestnet": false,
                "chainId": 56,
                "status": "ENABLED",
                "depositAddress": "0xdeposit",
                "tokens": [{ "token": "USDT", "tokenContractAddress": "0xbscusdt" }]
              }
            ]
            """
        )

        let tokens = TangemPayAccountTokensResolver().resolve(networks: networks)

        #expect(tokens.first?.tokenItem.decimalCount == 18)
    }

    @Test("The stables keep their coin id, so the row shows an icon and a rate")
    func stableSymbolsKeepTheirCoinId() throws {
        let networks = try makeTangemPayNetworks(
            """
            [
              {
                "name": "\(Blockchain.base(testnet: false).networkId)",
                "isTestnet": false,
                "chainId": 8453,
                "status": "ENABLED",
                "depositAddress": "0xdeposit",
                "tokens": [
                  { "token": "USDC", "tokenContractAddress": "0xbaseusdc" },
                  { "token": "usdt", "tokenContractAddress": "0xbaseusdt" },
                  { "token": "FOO", "tokenContractAddress": "0xfoo" }
                ]
              }
            ]
            """
        )

        let tokens = TangemPayAccountTokensResolver().resolve(networks: networks)

        #expect(tokens.map { $0.tokenItem.id } == ["usd-coin", "tether", nil])
    }

    @Test("An EVM network the name table doesn't list still resolves by its chain id")
    func unlistedEVMNetworkResolvesByChainId() throws {
        let networks = try makeTangemPayNetworks(
            """
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
        )

        let tokens = TangemPayAccountTokensResolver().resolve(networks: networks)

        #expect(tokens.map { $0.tokenItem.blockchain } == [.optimism(testnet: false)])
    }

    @Test("The BFF's chain id decides the network — it is what the withdraw request is addressed by")
    func chainIdWinsOverADisagreeingName() throws {
        let networks = try makeTangemPayNetworks(
            """
            [
              {
                "name": "\(Blockchain.polygon(testnet: false).networkId)",
                "isTestnet": false,
                "chainId": 8453,
                "status": "ENABLED",
                "depositAddress": "0xdeposit",
                "tokens": [{ "token": "USDC", "tokenContractAddress": "0xbaseusdc" }]
              }
            ]
            """
        )

        let tokens = TangemPayAccountTokensResolver().resolve(networks: networks)

        #expect(tokens.map { $0.tokenItem.blockchain } == [.base(testnet: false)])
    }

    @Test("A testnet the name table doesn't list stays unresolved — the chain id table is mainnet-only")
    func unlistedTestnetIsNotResolvedToItsMainnet() throws {
        let networks = try makeTangemPayNetworks(
            """
            [
              {
                "name": "op-sepolia",
                "isTestnet": true,
                "chainId": 10,
                "status": "ENABLED",
                "depositAddress": "0xdeposit",
                "tokens": [{ "token": "USDC", "tokenContractAddress": "0xopusdc" }]
              }
            ]
            """
        )

        #expect(TangemPayAccountTokensResolver().resolve(networks: networks).isEmpty)
    }

    @Test("A listed name whose chain id belongs to another network is dropped, not modelled by name")
    func namedNetworkDisagreeingWithAnUnlistedChainIdIsSkipped() throws {
        // 84532 is Base Sepolia — absent from the mainnet table, so the name would have answered.
        let networks = try makeTangemPayNetworks(
            """
            [
              {
                "name": "\(Blockchain.polygon(testnet: false).networkId)",
                "isTestnet": false,
                "chainId": 84532,
                "status": "ENABLED",
                "depositAddress": "0xdeposit",
                "tokens": [{ "token": "USDC", "tokenContractAddress": "0xusdc" }]
              }
            ]
            """
        )

        #expect(TangemPayAccountTokensResolver().resolve(networks: networks).isEmpty)
    }

    @Test("A testnet is taken at its name — the SDK's testnet chain ids trail the networks")
    func testnetIsNotHeldToItsChainId() throws {
        // Polygon's testnet is Amoy (80002); the SDK still names Mumbai.
        let networks = try makeTangemPayNetworks(
            """
            [
              {
                "name": "\(Blockchain.polygon(testnet: false).networkId)",
                "isTestnet": true,
                "chainId": 80002,
                "status": "ENABLED",
                "depositAddress": "0xdeposit",
                "tokens": [{ "token": "USDC", "tokenContractAddress": "0xusdc" }]
              }
            ]
            """
        )

        let tokens = TangemPayAccountTokensResolver().resolve(networks: networks)

        #expect(tokens.map { $0.tokenItem.blockchain } == [.polygon(testnet: true)])
    }

    @Test("The contract is normalised — Express compares it verbatim against the wallet's own token")
    func contractCasingMatchesTheWalletsToken() throws {
        // The BFF echoes a checksummed address; the catalog gives the wallet the lowercase one.
        let networks = try makeTangemPayNetworks(
            """
            [
              {
                "name": "\(Blockchain.base(testnet: false).networkId)",
                "isTestnet": false,
                "chainId": 8453,
                "status": "ENABLED",
                "depositAddress": "0xdeposit",
                "tokens": [
                  { "token": "USDC", "tokenContractAddress": "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913" }
                ]
              }
            ]
            """
        )

        let walletToken = TokenItem.token(
            Token(
                name: "USDC",
                symbol: "USDC",
                contractAddress: "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913",
                decimalCount: 6,
                metadata: .fungibleTokenMetadata
            ),
            BlockchainNetwork(.base(testnet: false), derivationPath: nil)
        )

        let tokens = TangemPayAccountTokensResolver().resolve(networks: networks)

        #expect(tokens.first?.tokenItem.expressCurrency == walletToken.expressCurrency)
    }

    /// Not the canonical USDC — its hardcoded item would mask how the rest are built.
    private static let usdtContract = "0xc2132D05D31c914a87C6611C10748AEb04B58e8F"
}
