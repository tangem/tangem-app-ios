//
//  OnrampSendSummaryTitleProviderTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemLocalization
import Testing
@testable import Tangem

@Suite("Onramp Buy screen network subtitle")
struct OnrampSendSummaryTitleProviderTests {
    @Test("A coin is labelled as the main network")
    func coinIsMainNetwork() {
        let sut = makeSUT(tokenItem: .blockchain(makeNetwork(.ethereum(testnet: false))))

        #expect(sut.subtitle == Localization.commonMainNetwork)
    }

    @Test("A token on a network with a standard names the standard and the network")
    func tokenWithStandard() {
        let sut = makeSUT(tokenItem: makeToken(on: .ethereum(testnet: false)))

        #expect(sut.subtitle == Localization.onrampBuyTitleSubtitleStandard("ERC20", "Ethereum"))
    }

    @Test("A token on a network without a standard names only the network")
    func tokenWithoutStandard() {
        let sut = makeSUT(tokenItem: makeToken(on: .solana(curve: .ed25519, testnet: false)))

        #expect(sut.subtitle == Localization.onrampBuyTitleSubtitleNetwork("Solana"))
    }

    @Test(
        "A network whose name already ends in Network isn't followed by the word again",
        arguments: [
            (Blockchain.xdc(testnet: false), "XDC"),
            (.areon(testnet: false), "Areon"),
            (.quai(testnet: false), "Quai"),
        ]
    )
    func networkWordIsNotRepeated(blockchain: Blockchain, networkName: String) {
        let sut = makeSUT(tokenItem: makeToken(on: blockchain))

        let expected = blockchain.tokenTypeName.map { Localization.onrampBuyTitleSubtitleStandard($0, networkName) }
            ?? Localization.onrampBuyTitleSubtitleNetwork(networkName)
        #expect(sut.subtitle == expected)
    }
}

// MARK: - Helpers

private extension OnrampSendSummaryTitleProviderTests {
    func makeSUT(tokenItem: TokenItem) -> OnrampSendSummaryTitleProvider {
        OnrampSendSummaryTitleProvider(tokenItem: tokenItem)
    }

    func makeNetwork(_ blockchain: Blockchain) -> BlockchainNetwork {
        BlockchainNetwork(blockchain, derivationPath: nil)
    }

    func makeToken(on blockchain: Blockchain) -> TokenItem {
        .token(
            Token(name: "USD Coin", symbol: "USDC", contractAddress: "0xUSDC", decimalCount: 6, id: "usd-coin"),
            makeNetwork(blockchain)
        )
    }
}
