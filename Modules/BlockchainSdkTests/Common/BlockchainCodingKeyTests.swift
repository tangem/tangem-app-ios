//
//  BlockchainCodingKeyTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Testing
import CryptoKit
import TangemSdk
import WalletCore
@testable import BlockchainSdk

struct BlockchainCodingKeyTests {
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    @Test
    func codingKeys() throws {
        BlockchainSdk.Blockchain.allMainnetCases.forEach {
            let recoveredFromCodable = try? decoder.decode(Blockchain.self, from: try encoder.encode($0))
            #expect(recoveredFromCodable == $0, "\($0.displayName)")
        }
    }

    @Test
    func robinhoodConfiguration() {
        let mainnet = Blockchain.robinhood(testnet: false)
        let testnet = Blockchain.robinhood(testnet: true)

        #expect(mainnet.chainId == 4663)
        #expect(testnet.chainId == 46630)
        #expect(mainnet.networkId == "robinhood")
        #expect(mainnet.coinId == "robinhood-ethereum")
        #expect(mainnet.currencySymbol == "ETH")
        #expect(mainnet.supportsEIP1559)
        #expect(mainnet.isL2EthereumNetwork)

        let mainnetLinks = ExternalLinkProviderFactory().makeProvider(for: mainnet)
        let testnetLinks = ExternalLinkProviderFactory().makeProvider(for: testnet)
        #expect(mainnetLinks.url(transaction: "hash")?.absoluteString == "https://robinhoodchain.blockscout.com/tx/hash")
        #expect(testnetLinks.url(address: "address", contractAddress: nil)?.absoluteString == "https://explorer.testnet.chain.robinhood.com/address/address")
    }

    @Test
    func igraConfiguration() {
        let mainnet = Blockchain.igra(testnet: false)
        let testnet = Blockchain.igra(testnet: true)

        #expect(mainnet.chainId == 38833)
        #expect(testnet.chainId == 38836)
        #expect(mainnet.networkId == "igra")
        #expect(mainnet.coinId == "igra-bridged-kaspa")
        #expect(mainnet.currencySymbol == "iKAS")
        #expect(mainnet.supportsEIP1559)

        let mainnetLinks = ExternalLinkProviderFactory().makeProvider(for: mainnet)
        let testnetLinks = ExternalLinkProviderFactory().makeProvider(for: testnet)
        #expect(mainnetLinks.url(transaction: "hash")?.absoluteString == "https://explorer.igralabs.com/tx/hash")
        #expect(testnetLinks.url(address: "address", contractAddress: nil)?.absoluteString == "https://explorer.galleon-testnet.igralabs.com/address/address")
    }

    @Test
    func electroneumConfiguration() {
        let mainnet = Blockchain.electroneum(testnet: false)
        let testnet = Blockchain.electroneum(testnet: true)

        #expect(mainnet.chainId == 52014)
        #expect(testnet.chainId == 5201420)
        #expect(mainnet.networkId == "electroneum")
        #expect(mainnet.coinId == "electroneum")
        #expect(mainnet.currencySymbol == "ETN")
        #expect(mainnet.supportsEIP1559)

        let mainnetLinks = ExternalLinkProviderFactory().makeProvider(for: mainnet)
        let testnetLinks = ExternalLinkProviderFactory().makeProvider(for: testnet)
        #expect(mainnetLinks.url(transaction: "hash")?.absoluteString == "https://blockexplorer.electroneum.com/tx/hash")
        #expect(testnetLinks.url(address: "address", contractAddress: nil)?.absoluteString == "https://testnet-blockexplorer.electroneum.com/address/address")
    }

    @Test
    func arcConfiguration() {
        let mainnet = Blockchain.arc(testnet: false)
        let testnet = Blockchain.arc(testnet: true)

        #expect(mainnet.chainId == 5042)
        #expect(testnet.chainId == 5042002)
        #expect(mainnet.networkId == "arc")
        #expect(mainnet.coinId == "usd-coin")
        #expect(mainnet.currencySymbol == "USDC")
        #expect(mainnet.decimalCount == 18)
        #expect(mainnet.displayDecimalCount == 6)
        #expect(mainnet.supportsEIP1559)

        let mainnetLinks = ExternalLinkProviderFactory().makeProvider(for: mainnet)
        let testnetLinks = ExternalLinkProviderFactory().makeProvider(for: testnet)
        #expect(mainnetLinks.url(transaction: "hash")?.absoluteString == "https://explorer.arc.io/tx/hash")
        #expect(testnetLinks.url(address: "address", contractAddress: nil)?.absoluteString == "https://testnet.arcscan.app/address/address")
        #expect(mainnetLinks.testnetFaucetURL == nil)
        #expect(testnetLinks.testnetFaucetURL?.absoluteString == "https://faucet.circle.com")
    }
}
