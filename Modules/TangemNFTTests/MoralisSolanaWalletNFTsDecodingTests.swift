//
//  MoralisSolanaWalletNFTsDecodingTests.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
import Foundation
@testable import TangemNFT

@Suite("MoralisSolanaWalletNFTsDecodingTests")
struct MoralisSolanaWalletNFTsDecodingTests {
    @Test
    func decodesWalletNFTsResponse() throws {
        let response = try MoralisSolanaFixtures.decodeResponse(MoralisSolanaFixtures.coreResponse)

        #expect(response.cursor == "next-page")
        #expect(response.meta?.failedChains?.isEmpty == true)
        #expect(response.result?.count == 2)

        let item = try #require(response.result?.first)
        #expect(item.tokenAddress == "CoreAsset1111111111111111111111111111111111")
        #expect(item.tokenStandard == "MplCore")
        #expect(item.collection?.address == "CoreCollection11111111111111111111111111111")
        #expect(item.metadata?.attributes?.first?.traitType == "Background")
        #expect(item.media?.mediaCollection?.high?.url == "https://media.moralis.io/high.png")
    }

    @Test
    func decodesFailedChains() throws {
        let response = try MoralisSolanaFixtures.decodeResponse(MoralisSolanaFixtures.failedChainResponse)

        let failure = try #require(response.meta?.failedChains?.first)
        #expect(failure.chainId == "solana-mainnet")
        #expect(failure.code == "INTERNAL_SERVER_ERROR")
        #expect(response.result?.isEmpty == true)
    }
}
