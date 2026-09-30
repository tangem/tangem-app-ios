//
//  ExternalLinkProviderURLTests.swift
//  BlockchainSdkTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import BlockchainSdk

@Suite("External link providers — URL shape")
struct ExternalLinkProviderURLTests {
    @Test("Solana testnet account + token URL has a single query string and a fragment")
    func solanaTestnetTokenURL() {
        let url = SolanaExternalLinkProvider(isTestnet: true).url(address: "Acc", contractAddress: "Tok")

        #expect(url?.absoluteString == "https://solscan.io/account/Acc?cluster=testnet&token_address=Tok#transfers")
    }

    @Test("Solana mainnet account + token URL")
    func solanaMainnetTokenURL() {
        let url = SolanaExternalLinkProvider(isTestnet: false).url(address: "Acc", contractAddress: "Tok")

        #expect(url?.absoluteString == "https://solscan.io/account/Acc?token_address=Tok#transfers")
    }

    @Test("Solana account URL without a token keeps the cluster query")
    func solanaAccountURL() {
        #expect(SolanaExternalLinkProvider(isTestnet: true).url(address: "Acc", contractAddress: nil)?.absoluteString == "https://solscan.io/account/Acc?cluster=testnet")
        #expect(SolanaExternalLinkProvider(isTestnet: false).url(address: "Acc", contractAddress: nil)?.absoluteString == "https://solscan.io/account/Acc")
    }

    @Test("Moonbeam NFT URL keeps the slash between host and path")
    func moonbeamNFTURL() {
        let url = MoonbeamExternalLinkProvider(isTestnet: false).url(tokenAddress: "0xabc", tokenID: "7", contractType: "ERC721")

        #expect(url?.host == "moonscan.io")
        #expect(url?.absoluteString == "https://moonscan.io/nft/0xabc/7")
    }

    @Test("Ethereum testnet links point at Sepolia")
    func ethereumTestnetLinks() {
        let provider = EthereumExternalLinkProvider(isTestnet: true)

        #expect(provider.url(transaction: "0x1")?.absoluteString == "https://sepolia.etherscan.io/tx/0x1")
        #expect(provider.url(address: "0x2", contractAddress: nil)?.absoluteString == "https://sepolia.etherscan.io/address/0x2")
        #expect(provider.testnetFaucetURL?.host?.hasSuffix("alchemy.com") == true)
    }
}
