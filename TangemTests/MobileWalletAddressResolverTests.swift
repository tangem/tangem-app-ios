//
//  MobileWalletAddressResolverTests.swift
//  TangemTests
//
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem
@testable import TangemMobileWalletSdk
import BlockchainSdk
import TangemSdk
import TangemFoundation

class MobileWalletAddressResolverTests {
    private let userWalletId = UserWalletId(with: Data(hexString: "0374d0f81f42ddfe34114d533e95e6ae5fe6ea271c96f1fa505199fdc365ae9720"))

    @Test
    func testResolveStandardEVMNetworks() async throws {
        let mnemonic = try Mnemonic(with: "tiny escape drive pupil flavor endless love walk gadget match filter luxury")
        let walletInfo = try await MobileWalletInitializer().initializeWallet(mnemonic: mnemonic, passphrase: nil)
        try? CommonMobileWalletSdk().delete(walletIDs: [userWalletId])

        let blockchains: Set<Blockchain> = [
            .ethereum(testnet: false),
            .polygon(testnet: false),
            .bsc(testnet: false),
        ]
        let resolver = InitialWalletTokenSyncAddressResolver()
        let result = resolver.resolve(keyInfos: walletInfo.keys, supportedBlockchains: blockchains)

        let data = try jsonData(for: "test_addresses")
        let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: String])

        #expect(result.count == blockchains.count)
        for pair in result {
            let expected = json[pair.blockchainNetwork.blockchain.networkId]
            #expect(expected == pair.address, "\(pair.blockchainNetwork.blockchain.displayName): expected \(expected ?? "nil"), got \(pair.address)")
        }
    }

    @Test
    func testOnlyMoralisSupportedNetworks() async throws {
        let mnemonic = try Mnemonic(with: "tiny escape drive pupil flavor endless love walk gadget match filter luxury")
        let walletInfo = try await MobileWalletInitializer().initializeWallet(mnemonic: mnemonic, passphrase: nil)
        try? CommonMobileWalletSdk().delete(walletIDs: [userWalletId])

        let allBlockchains = SupportedBlockchains(version: .v2).blockchains()
        let resolver = InitialWalletTokenSyncAddressResolver()
        let result = resolver.resolve(keyInfos: walletInfo.keys, supportedBlockchains: allBlockchains)

        for pair in result {
            #expect(
                MoralisSupportedBlockchains.networkIds.contains(pair.blockchainNetwork.blockchain.networkId),
                "Result must only contain Moralis-supported networks, got \(pair.blockchainNetwork.blockchain.networkId)"
            )
        }
    }

    @Test
    func testNoDuplicates() async throws {
        let mnemonic = try Mnemonic(with: "tiny escape drive pupil flavor endless love walk gadget match filter luxury")
        let walletInfo = try await MobileWalletInitializer().initializeWallet(mnemonic: mnemonic, passphrase: nil)
        try? CommonMobileWalletSdk().delete(walletIDs: [userWalletId])

        let blockchains: Set<Blockchain> = [
            .ethereum(testnet: false),
            .polygon(testnet: false),
        ]
        let resolver = InitialWalletTokenSyncAddressResolver()
        let result = resolver.resolve(keyInfos: walletInfo.keys, supportedBlockchains: blockchains)

        let networkIds = result.map { $0.blockchainNetwork.blockchain.networkId }
        let uniqueIds = Set(networkIds)
        #expect(uniqueIds.count == result.count, "Result must not contain duplicate blockchain networks")
    }

    @Test
    func testPartialResultWhenKeyInfoMissingForCurve() async throws {
        let mnemonic = try Mnemonic(with: "tiny escape drive pupil flavor endless love walk gadget match filter luxury")
        let walletInfo = try await MobileWalletInitializer().initializeWallet(mnemonic: mnemonic, passphrase: nil)
        try? CommonMobileWalletSdk().delete(walletIDs: [userWalletId])

        let keyInfosOnlySecp = walletInfo.keys.filter { $0.curve == .secp256k1 }
        let resolver = InitialWalletTokenSyncAddressResolver()
        let blockchains: Set<Blockchain> = [
            .ethereum(testnet: false),
            .polygon(testnet: false),
            .solana(testnet: false),
        ]
        let result = resolver.resolve(keyInfos: keyInfosOnlySecp, supportedBlockchains: blockchains)

        let networkIds = Set(result.map { $0.blockchainNetwork.blockchain.networkId })
        #expect(networkIds.contains(Blockchain.ethereum(testnet: false).networkId))
        #expect(networkIds.contains(Blockchain.polygon(testnet: false).networkId))
        #expect(!networkIds.contains(Blockchain.solana(testnet: false).networkId), "Solana requires ed25519 key, should be skipped when only secp256k1 keys provided")
    }

    @Test
    func testCardanoNotInResultWhenUsingMoralisFilter() async throws {
        let mnemonic = try Mnemonic(with: "tiny escape drive pupil flavor endless love walk gadget match filter luxury")
        let walletInfo = try await MobileWalletInitializer().initializeWallet(mnemonic: mnemonic, passphrase: nil)
        try? CommonMobileWalletSdk().delete(walletIDs: [userWalletId])

        let blockchainsIncludingCardano = SupportedBlockchains(version: .v2).blockchains()
        #expect(blockchainsIncludingCardano.contains(where: { $0.networkId == Blockchain.cardano(extended: true).networkId }))

        let resolver = InitialWalletTokenSyncAddressResolver()
        let result = resolver.resolve(keyInfos: walletInfo.keys, supportedBlockchains: blockchainsIncludingCardano)

        let hasCardano = result.contains { $0.blockchainNetwork.blockchain.networkId == Blockchain.cardano(extended: true).networkId }
        #expect(!hasCardano, "Cardano is not in Moralis allow-list so must not appear in result")
    }

    @Test
    func testQuaiNotInResultWhenUsingMoralisFilter() async throws {
        let blockchainsIncludingQuai: Set<Blockchain> = [
            .ethereum(testnet: false),
            .quai(testnet: false),
        ]
        #expect(MoralisSupportedBlockchains.networkIds.contains(Blockchain.quai(testnet: false).networkId) == false)

        let resolver = InitialWalletTokenSyncAddressResolver()
        let keyInfos: [KeyInfo] = []
        let result = resolver.resolve(keyInfos: keyInfos, supportedBlockchains: blockchainsIncludingQuai)

        let hasQuai = result.contains { $0.blockchainNetwork.blockchain.networkId == Blockchain.quai(testnet: false).networkId }
        #expect(!hasQuai, "Quai is not in Moralis allow-list so must not appear in result")
    }

    @Test
    func testWalletAddressResolverResolvesSingleAddress() async throws {
        let mnemonic = try Mnemonic(with: "tiny escape drive pupil flavor endless love walk gadget match filter luxury")
        let walletInfo = try await MobileWalletInitializer().initializeWallet(mnemonic: mnemonic, passphrase: nil)
        try? CommonMobileWalletSdk().delete(walletIDs: [userWalletId])

        let resolver = WalletAddressResolver()
        let pair = try resolver.resolveAddress(for: .ethereum(testnet: false), keyInfos: walletInfo.keys)

        let data = try jsonData(for: "test_addresses")
        let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: String])
        let expected = json[Blockchain.ethereum(testnet: false).networkId]
        #expect(pair.address == expected)
    }

    @Test
    func testWalletAddressResolverThrowsUnsupportedBlockchain() async throws {
        let resolver = WalletAddressResolver()
        let keyInfos: [KeyInfo] = []

        #expect(throws: WalletAddressResolver.Error.self) {
            _ = try resolver.resolveAddress(for: .hedera(curve: .ed25519_slip0010, testnet: false), keyInfos: keyInfos)
        }
    }

    private func jsonData(for fileName: String) throws -> Data {
        let bundle = Bundle(for: MobileWalletAddressResolverTests.self)
        let path = try #require(bundle.path(forResource: fileName, ofType: "json"))
        let string = try String(contentsOfFile: path)
        return try #require(string.data(using: .utf8))
    }
}
