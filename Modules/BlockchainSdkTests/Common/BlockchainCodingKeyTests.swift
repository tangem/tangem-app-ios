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

    @Test
    func publicMasterpieceConfiguration() {
        let blockchain = Blockchain.publicMasterpiece

        #expect(blockchain.chainId == 290290)
        #expect(blockchain.isTestnet == false)
        #expect(blockchain.networkId == "public-masterpiece")
        #expect(blockchain.coinId == "public-meme-token")
        #expect(blockchain.currencySymbol == "PMT")
        #expect(blockchain.decimalCount == 18)
        #expect(blockchain.displayName == "Public Masterpiece")
        #expect(blockchain.supportsEIP1559)
        #expect(blockchain.canHandleTokens == false)

        let links = ExternalLinkProviderFactory().makeProvider(for: blockchain)
        #expect(links.url(transaction: "hash")?.absoluteString == "https://pmtscan.com/tx/hash")
        #expect(links.url(address: "address", contractAddress: nil)?.absoluteString == "https://pmtscan.com/address/address")
        #expect(links.testnetFaucetURL == nil)
    }

    @Test
    func onyxConfiguration() {
        let mainnet = Blockchain.onyx(testnet: false)
        let testnet = Blockchain.onyx(testnet: true)

        #expect(mainnet.chainId == 327)
        #expect(testnet.chainId == 8901)
        #expect(mainnet.networkId == "onyx")
        #expect(mainnet.coinId == "chain-2")
        #expect(mainnet.currencySymbol == "XCN")
        #expect(mainnet.decimalCount == 18)
        #expect(mainnet.displayDecimalCount == 8)
        #expect(!mainnet.supportsEIP1559)

        let mainnetLinks = ExternalLinkProviderFactory().makeProvider(for: mainnet)
        let testnetLinks = ExternalLinkProviderFactory().makeProvider(for: testnet)
        #expect(mainnetLinks.url(transaction: "hash")?.absoluteString == "https://explorer.onyx.org/tx/hash")
        #expect(testnetLinks.url(address: "address", contractAddress: nil)?.absoluteString == "https://testnet.explorer.goliath.net/address/address")
        #expect(mainnetLinks.testnetFaucetURL == nil)
        #expect(testnetLinks.testnetFaucetURL == nil)
    }

    @Test
    func zeniqConfiguration() {
        let blockchain = Blockchain.zeniq

        #expect(blockchain.chainId == 383414847825)
        #expect(blockchain.isTestnet == false)
        #expect(blockchain.networkId == "zeniq")
        #expect(blockchain.coinId == "zeniq")
        #expect(blockchain.currencySymbol == "ZENIQ")
        #expect(blockchain.decimalCount == 18)
        #expect(blockchain.displayName == "Zeniq")
        #expect(!blockchain.supportsEIP1559)

        let links = ExternalLinkProviderFactory().makeProvider(for: blockchain)
        #expect(links.url(transaction: "hash")?.absoluteString == "https://zeniqscan.com/tx/hash")
        #expect(links.url(address: "address", contractAddress: nil)?.absoluteString == "https://zeniqscan.com/address/address")
        #expect(links.testnetFaucetURL == nil)
    }

    @Test
    func katanaConfiguration() {
        let mainnet = Blockchain.katana(testnet: false)
        let testnet = Blockchain.katana(testnet: true)

        #expect(mainnet.chainId == 747474)
        #expect(testnet.chainId == 737373)
        #expect(mainnet.networkId == "katana")
        #expect(mainnet.coinId == "katana-ethereum")
        #expect(mainnet.currencySymbol == "ETH")
        #expect(mainnet.decimalCount == 18)
        #expect(mainnet.isL2EthereumNetwork)
        #expect(mainnet.supportsEIP1559)
        #expect(mainnet.canHandleTokens)

        let mainnetLinks = ExternalLinkProviderFactory().makeProvider(for: mainnet)
        let testnetLinks = ExternalLinkProviderFactory().makeProvider(for: testnet)
        #expect(mainnetLinks.url(transaction: "hash")?.absoluteString == "https://katanascan.com/tx/hash")
        #expect(testnetLinks.url(address: "address", contractAddress: nil)?.absoluteString == "https://bokuto.katanascan.com/address/address")
        #expect(mainnetLinks.testnetFaucetURL == nil)
        #expect(testnetLinks.testnetFaucetURL == nil)
    }

    @Test
    func xLayerConfiguration() {
        let mainnet = Blockchain.xLayer(testnet: false)
        let testnet = Blockchain.xLayer(testnet: true)

        #expect(mainnet.chainId == 196)
        #expect(testnet.chainId == 1952)
        #expect(mainnet.networkId == "x-layer")
        #expect(mainnet.coinId == "okb")
        #expect(mainnet.currencySymbol == "OKB")
        #expect(mainnet.decimalCount == 18)
        #expect(!mainnet.isL2EthereumNetwork)
        #expect(mainnet.supportsEIP1559)

        let mainnetLinks = ExternalLinkProviderFactory().makeProvider(for: mainnet)
        let testnetLinks = ExternalLinkProviderFactory().makeProvider(for: testnet)
        #expect(mainnetLinks.url(transaction: "hash")?.absoluteString == "https://web3.okx.com/explorer/x-layer/tx/hash")
        #expect(testnetLinks.url(address: "address", contractAddress: nil)?.absoluteString == "https://web3.okx.com/explorer/xlayer-test/address/address")
        #expect(mainnetLinks.testnetFaucetURL == nil)
        #expect(testnetLinks.testnetFaucetURL?.absoluteString == "https://web3.okx.com/xlayer/faucet")
    }

    @Test
    func inkConfiguration() {
        let mainnet = Blockchain.ink(testnet: false)
        let testnet = Blockchain.ink(testnet: true)

        #expect(mainnet.chainId == 57073)
        #expect(testnet.chainId == 763373)
        #expect(mainnet.networkId == "ink")
        #expect(mainnet.coinId == "ink-ethereum")
        #expect(mainnet.currencySymbol == "ETH")
        #expect(mainnet.decimalCount == 18)
        #expect(mainnet.isL2EthereumNetwork)
        #expect(mainnet.supportsEIP1559)
        #expect(mainnet.canHandleTokens)

        let mainnetLinks = ExternalLinkProviderFactory().makeProvider(for: mainnet)
        let testnetLinks = ExternalLinkProviderFactory().makeProvider(for: testnet)
        #expect(mainnetLinks.url(transaction: "hash")?.absoluteString == "https://explorer.inkonchain.com/tx/hash")
        #expect(testnetLinks.url(address: "address", contractAddress: nil)?.absoluteString == "https://explorer-sepolia.inkonchain.com/address/address")
        #expect(mainnetLinks.testnetFaucetURL == nil)
        #expect(testnetLinks.testnetFaucetURL == nil)
    }
}
