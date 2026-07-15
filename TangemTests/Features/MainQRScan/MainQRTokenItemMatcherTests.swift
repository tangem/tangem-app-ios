//
//  MainQRTokenItemMatcherTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem
@testable import BlockchainSdk

@Suite("MainQRTokenItemMatcher")
struct MainQRTokenItemMatcherTests {
    private let matcher = MainQRTokenItemMatcher()
    private let usdtContract = "0xdAC17F958D2ee523a2206206994597C13D831ec7"

    @Test("Matches a token by contract address, case-insensitively")
    func matchesByContract() {
        let usdt = tokenItem(symbol: "USDT", contract: usdtContract)

        let result = matcher.matchTokenItems(
            for: makeRequest(tokenContractAddress: usdtContract.lowercased()),
            availableTokenItems: [coinItem(), usdt],
            availableBlockchains: [.ethereum(testnet: false)]
        )

        #expect(result == [usdt])
    }

    @Test("Matches a token by symbol when no contract is provided")
    func matchesBySymbol() {
        let usdt = tokenItem(symbol: "USDT", contract: usdtContract)

        let result = matcher.matchTokenItems(
            for: makeRequest(tokenSymbol: "usdt"),
            availableTokenItems: [coinItem(), usdt],
            availableBlockchains: [.ethereum(testnet: false)]
        )

        #expect(result == [usdt])
    }

    @Test("Returns empty when a specific token is requested but not available")
    func specificTokenNotFound() {
        let usdt = tokenItem(symbol: "USDT", contract: usdtContract)

        let result = matcher.matchTokenItems(
            for: makeRequest(tokenSymbol: "UNKNOWN"),
            availableTokenItems: [coinItem(), usdt],
            availableBlockchains: [.ethereum(testnet: false)]
        )

        #expect(result.isEmpty)
    }

    @Test("Falls back to the native coin when no token is specified")
    func fallsBackToCoin() {
        let coin = coinItem()
        let usdt = tokenItem(symbol: "USDT", contract: usdtContract)

        let result = matcher.matchTokenItems(
            for: makeRequest(),
            availableTokenItems: [coin, usdt],
            availableBlockchains: [.ethereum(testnet: false)]
        )

        #expect(result == [coin])
    }

    @Test("Produces a synthetic native coin item when nothing is added for the blockchain yet")
    func syntheticCoinWhenEmpty() {
        let result = matcher.matchTokenItems(
            for: makeRequest(),
            availableTokenItems: [],
            availableBlockchains: [.ethereum(testnet: false)]
        )

        #expect(result == [.blockchain(BlockchainNetwork(.ethereum(testnet: false), derivationPath: nil))])
    }

    // MARK: - Fixtures

    private func makeRequest(
        blockchain: Blockchain = .ethereum(testnet: false),
        destination: String = "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb",
        tokenSymbol: String? = nil,
        tokenContractAddress: String? = nil
    ) -> MainQRPaymentRequest {
        MainQRPaymentRequest(
            blockchain: blockchain,
            destinationAddress: destination,
            amount: nil,
            memo: nil,
            tokenSymbol: tokenSymbol,
            tokenContractAddress: tokenContractAddress,
            rawTokenAmount: nil
        )
    }

    private func coinItem(_ blockchain: Blockchain = .ethereum(testnet: false)) -> TokenItem {
        .blockchain(BlockchainNetwork(blockchain, derivationPath: nil))
    }

    private func tokenItem(
        symbol: String,
        contract: String,
        blockchain: Blockchain = .ethereum(testnet: false)
    ) -> TokenItem {
        .token(
            Token(name: symbol, symbol: symbol, contractAddress: contract, decimalCount: 6),
            BlockchainNetwork(blockchain, derivationPath: nil)
        )
    }
}
