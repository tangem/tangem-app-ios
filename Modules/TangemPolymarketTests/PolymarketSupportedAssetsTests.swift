//
//  PolymarketSupportedAssetsTests.swift
//  TangemPolymarketTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemPolymarket

// MARK: - Fixtures

private enum PolymarketDepositFixtures {
    static let supportedAssets = Data(
        #"""
        {
          "supportedAssets": [
            {
              "chainId": "1",
              "chainName": "Ethereum",
              "token": { "name": "Ethereum ETH", "symbol": "ETH", "address": "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE", "decimals": 18 },
              "minCheckoutUsd": 5
            },
            {
              "chainId": "137",
              "chainName": "Polygon",
              "token": { "name": "Wrapped Ether", "symbol": "WETH", "address": "0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619", "decimals": 18 },
              "minCheckoutUsd": 2
            },
            {
              "chainId": "137",
              "chainName": "Polygon",
              "token": { "name": "Wrapped Ether (bridged)", "symbol": "WETH", "address": "0x11CD37bb86F65419713f30673A480EA33c826872", "decimals": 18 },
              "minCheckoutUsd": 25
            },
            {
              "chainId": "1151111081099710",
              "chainName": "Solana",
              "token": { "name": "Solana SOL", "symbol": "SOL", "address": "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE", "decimals": 9 },
              "minCheckoutUsd": 2
            },
            {
              "chainId": "1151111081099710",
              "chainName": "Solana",
              "token": { "name": "SOL", "symbol": "SOL", "address": "11111111111111111111111111111111", "decimals": 9 },
              "minCheckoutUsd": 2
            },
            {
              "chainId": "8253038",
              "chainName": "Bitcoin",
              "token": { "name": "Bitcoin", "symbol": "BTC", "address": "bc1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqmql8k8", "decimals": 8 },
              "minCheckoutUsd": 7
            },
            {
              "chainId": "728126428",
              "chainName": "Tron",
              "token": { "name": "Tether USD", "symbol": "USDT", "address": "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t", "decimals": 6 },
              "minCheckoutUsd": 7
            },
            {
              "chainId": "784",
              "chainName": "Sui",
              "token": { "name": "Sui", "symbol": "SUI", "address": "0x2::sui::SUI", "decimals": 9 },
              "minCheckoutUsd": 2
            }
          ],
          "note": "These are the currently supported chains and assets for deposits and withdrawals."
        }
        """#.utf8
    )

    static let fundingAddresses = Data(
        #"""
        {
          "address": {
            "evm": "0x2222222222222222222222222222222222222222",
            "svm": "SvmFundingAddressPlaceholder22222222222222",
            "tron": "TronFundingAddressPlaceholder2222222222",
            "btc": "bc1qfundingaddressplaceholder22222222222222"
          },
          "note": "Only certain chains and tokens are supported. See /supported-assets for details."
        }
        """#.utf8
    )
}

// MARK: - Supported assets decoding

@Suite("Polymarket supported assets decoding")
struct PolymarketSupportedAssetsDecodingTests {
    private let decoder = JSONDecoder()
    private let mapper = PolymarketMapper()

    @Test("The list arrives wrapped in an object, not as a bare array")
    func responseIsWrapped() throws {
        let response = try decoder.decode(PolymarketDTO.SupportedAssetsResponse.self, from: PolymarketDepositFixtures.supportedAssets)

        #expect(response.supportedAssets.count == 8)
    }

    @Test("Token fields are nested under token, and the chain id stays a string")
    func nestedTokenAndStringChainId() throws {
        let assets = try mapAssets()
        let bitcoin = try #require(assets.first { $0.chainName == "Bitcoin" })

        #expect(bitcoin.chainId == "8253038")
        #expect(bitcoin.family == .btc)
        #expect(bitcoin.token.symbol == "BTC")
        #expect(bitcoin.token.address == "bc1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqmql8k8")
        #expect(bitcoin.token.decimalCount == 8)
    }

    @Test("The minimum is carried per asset, not per chain")
    func minimumIsPerAsset() throws {
        let assets = try mapAssets()
        let polygon = assets.filter { $0.chainId == "137" }

        #expect(polygon.count == 2)
        #expect(polygon.first { $0.token.address == "0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619" }?.minCheckoutUSD == 2)
        #expect(polygon.first { $0.token.address == "0x11CD37bb86F65419713f30673A480EA33c826872" }?.minCheckoutUSD == 25)
    }

    @Test("An asset on a chain with no known address family is dropped rather than served an EVM address")
    func unknownFamilyIsDropped() throws {
        let response = try decoder.decode(PolymarketDTO.SupportedAssetsResponse.self, from: PolymarketDepositFixtures.supportedAssets)
        let assets = mapper.mapSupportedAssets(response)

        #expect(response.supportedAssets.contains { $0.chainName == "Sui" })
        #expect(!assets.contains { $0.chainName == "Sui" })
        #expect(assets.count == response.supportedAssets.count - 1)
    }

    @Test("Everything the bridge can address survives the mapping, whatever the family")
    func everyKnownFamilySurvives() throws {
        let assets = try mapAssets()

        #expect(Set(assets.map(\.family)) == Set(PolymarketChainFamily.allCases))
    }

    private func mapAssets() throws -> [PolymarketSupportedAsset] {
        let response = try decoder.decode(PolymarketDTO.SupportedAssetsResponse.self, from: PolymarketDepositFixtures.supportedAssets)
        return mapper.mapSupportedAssets(response)
    }
}

// MARK: - Chain family

@Suite("Polymarket chain family")
struct PolymarketChainFamilyTests {
    private let chainIdPerFamily: [PolymarketChainFamily: String] = [
        .evm: "1",
        .svm: "1151111081099710",
        .tron: "728126428",
        .btc: "8253038",
    ]

    @Test("Every family is reachable from some chain id, so a new family cannot be left unmapped")
    func everyFamilyIsReachable() {
        #expect(Set(chainIdPerFamily.keys) == Set(PolymarketChainFamily.allCases))

        for (family, chainId) in chainIdPerFamily {
            #expect(PolymarketChainFamily(chainId: chainId) == family)
        }
    }

    @Test(
        "All the EVM chains the bridge currently lists resolve to the EVM family",
        arguments: ["1", "10", "56", "137", "143", "999", "4663", "8453", "42161", "57073"]
    )
    func listedEVMChainIds(chainId: String) {
        #expect(PolymarketChainFamily(chainId: chainId) == .evm)
    }

    @Test(
        "An unlisted chain id has no family, rather than defaulting to EVM and handing out a wrong-chain address",
        arguments: ["784", "0", "1000000", "", "not-a-chain"]
    )
    func unlistedChainIdHasNoFamily(chainId: String) {
        #expect(PolymarketChainFamily(chainId: chainId) == nil)
    }
}

// MARK: - Asset identity

@Suite("Polymarket supported asset identity")
struct PolymarketSupportedAssetIdentityTests {
    private let decoder = JSONDecoder()
    private let mapper = PolymarketMapper()

    @Test("Two assets sharing a symbol on one chain stay distinct, because only chain plus address is unique")
    func sameSymbolDifferentAddress() throws {
        let response = try decoder.decode(PolymarketDTO.SupportedAssetsResponse.self, from: PolymarketDepositFixtures.supportedAssets)
        let assets = mapper.mapSupportedAssets(response)
        let polygonWETH = assets.filter { $0.chainId == "137" && $0.token.symbol == "WETH" }

        #expect(polygonWETH.count == 2)
        #expect(Set(polygonWETH.map(\.id)).count == 2)
    }

    @Test("The bridge lists a chain's native coin twice, and both survive as separate assets")
    func nativeCoinListedTwice() throws {
        let response = try decoder.decode(PolymarketDTO.SupportedAssetsResponse.self, from: PolymarketDepositFixtures.supportedAssets)
        let assets = mapper.mapSupportedAssets(response)
        let solana = assets.filter { $0.chainId == "1151111081099710" && $0.token.symbol == "SOL" }

        #expect(solana.count == 2)
        #expect(Set(solana.map(\.id)).count == 2)
        #expect(Set(solana.map(\.family)) == [.svm])
    }

    @Test("The identifier keeps the address exactly as delivered, because base58 chains are case sensitive")
    func identifierPreservesAddressCasing() {
        let solanaAddress = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"
        let asset = makeAsset(chainId: "1151111081099710", family: .svm, address: solanaAddress)

        #expect(asset.id.tokenAddress == solanaAddress)
        #expect(asset.id != makeAsset(chainId: "1151111081099710", family: .svm, address: solanaAddress.lowercased()).id)
    }

    @Test("The same address on two chains is two assets")
    func sameAddressDifferentChains() {
        let address = "0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619"
        let onPolygon = makeAsset(chainId: "137", family: .evm, address: address)
        let onBase = makeAsset(chainId: "8453", family: .evm, address: address)

        #expect(onPolygon.id != onBase.id)
    }

    private func makeAsset(chainId: String, family: PolymarketChainFamily, address: String) -> PolymarketSupportedAsset {
        PolymarketSupportedAsset(
            chainId: chainId,
            chainName: "Chain",
            family: family,
            token: PolymarketSupportedAsset.Token(name: "Token", symbol: "TKN", address: address, decimalCount: 18),
            minCheckoutUSD: 2
        )
    }
}

// MARK: - Funding addresses

@Suite("Polymarket bridge funding addresses")
struct PolymarketBridgeAddressesTests {
    private let decoder = JSONDecoder()
    private let mapper = PolymarketMapper()

    @Test("Every family the bridge can answer with resolves to its own address")
    func addressPerFamily() throws {
        let dto = try decoder.decode(PolymarketDTO.FundingAddressesResponse.self, from: PolymarketDepositFixtures.fundingAddresses)
        let addresses = mapper.mapBridgeAddresses(dto)

        let expected: [PolymarketChainFamily: String] = [
            .evm: "0x2222222222222222222222222222222222222222",
            .svm: "SvmFundingAddressPlaceholder22222222222222",
            .btc: "bc1qfundingaddressplaceholder22222222222222",
            .tron: "TronFundingAddressPlaceholder2222222222",
        ]

        #expect(Set(expected.keys) == Set(PolymarketChainFamily.allCases))

        for family in PolymarketChainFamily.allCases {
            #expect(addresses.address(for: family) == expected[family])
        }
    }

    @Test("A flat body fails on the missing envelope, so no top-level fallback can creep back in")
    func addressesAreWrapped() throws {
        let flatBody = Data(#"{ "evm": "0xabc" }"#.utf8)

        do {
            _ = try decoder.decode(PolymarketDTO.FundingAddressesResponse.self, from: flatBody)
            Issue.record("Expected decoding a flat body to fail")
        } catch DecodingError.keyNotFound(let key, _) {
            #expect(key.stringValue == "address")
        }
    }

    @Test("A family the bridge did not return has no address, rather than borrowing another family's")
    func missingFamilyHasNoAddress() throws {
        let body = Data(#"{ "address": { "evm": "0xabc" } }"#.utf8)

        let dto = try decoder.decode(PolymarketDTO.FundingAddressesResponse.self, from: body)
        let addresses = mapper.mapBridgeAddresses(dto)

        #expect(addresses.address(for: .evm) == "0xabc")

        for family in PolymarketChainFamily.allCases where family != .evm {
            #expect(addresses.address(for: family) == nil)
        }
    }

    @Test("An empty string is not an address")
    func emptyAddressIsDropped() throws {
        let body = Data(#"{ "address": { "evm": "0xabc", "tron": "" } }"#.utf8)

        let dto = try decoder.decode(PolymarketDTO.FundingAddressesResponse.self, from: body)
        let addresses = mapper.mapBridgeAddresses(dto)

        #expect(addresses.address(for: .tron) == nil)
    }
}
