//
//  WalletAssetsDiscoveryAddressResolverTests.swift
//  TangemTests
//
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
@testable import Tangem
@testable import TangemMobileWalletSdk
import BlockchainSdk
import TangemSdk

class WalletAssetsDiscoveryAddressResolverTests {
    private static let testMnemonic = "tiny escape drive pupil flavor endless love walk gadget match filter luxury"

    private let userWalletId = UserWalletId(with: Data(hexString: "0374d0f81f42ddfe34114d533e95e6ae5fe6ea271c96f1fa505199fdc365ae9720"))

    private func walletInfo() async throws -> MobileWalletInfo {
        let mnemonic = try Mnemonic(with: Self.testMnemonic)
        return try await MobileWalletInitializer().initializeWallet(mnemonic: mnemonic, passphrase: nil)
    }

    private let walletAddressResolver = WalletAddressResolver()

    @Test
    func resolvesAddressesForWalletAssetsDiscoveryBlockchainsInV3Config() async throws {
        let info = try await walletInfo()
        defer { try? CommonMobileWalletSdk().delete(walletIDs: [userWalletId]) }

        let config = MobileUserWalletConfig(mobileWalletInfo: info)
        let derivationStyle = try #require(config.derivationStyle)
        let keys = info.keys

        let supportedBlockchains = config.supportedBlockchains.filter(isWalletAssetsDiscoverySupported)
        let result = try supportedBlockchains.map { blockchain -> NetworkAddressPair in
            let blockchainNetwork = BlockchainNetwork(blockchain, derivationPath: blockchain.derivationPath(for: derivationStyle))
            return try walletAddressResolver.resolveAddress(for: blockchainNetwork, keyInfos: keys)
        }

        let expectedNetworkIds = Set(supportedBlockchains.map { $0.networkId })
        let resolvedNetworkIds = Set(result.map { $0.blockchainNetwork.blockchain.networkId })
        let missing = expectedNetworkIds.subtracting(resolvedNetworkIds)

        #expect(missing.isEmpty, "Resolver failed for \(missing.count) blockchains: \(missing.sorted().joined(separator: ", "))")

        for pair in result {
            let expected = try expectedAddress(for: pair.blockchainNetwork.blockchain)
            #expect(pair.address == expected, "\(pair.blockchainNetwork.blockchain.displayName)")
        }
    }

    private func expectedAddress(for blockchain: Blockchain) throws -> String {
        let bundle = Bundle(for: WalletAssetsDiscoveryAddressResolverTests.self)
        let path = try #require(bundle.path(forResource: "test_addresses", ofType: "json"))
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: String])
        return try #require(json[blockchain.networkId])
    }

    /// Mirrors relayer selection logic from `WalletAssetsDiscoveryOrchestratorFactory.makeRelayerFactory`.
    private func isWalletAssetsDiscoverySupported(_ blockchain: Blockchain) -> Bool {
        if isConfigurationRelayerSupported(blockchain) {
            return true
        }

        if isMoralisRelayerSupported(blockchain) {
            return true
        }

        return false
    }

    private func isConfigurationRelayerSupported(_ blockchain: Blockchain) -> Bool {
        switch blockchain {
        case .solana, .xrp, .tron:
            return true
        default:
            return false
        }
    }

    private func isMoralisRelayerSupported(_ blockchain: Blockchain) -> Bool {
        MoralisSupportedBlockchains.all.contains(blockchain)
    }
}
