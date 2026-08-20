//
//  TangemPayAccountTokensTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Foundation
import Testing
@testable import Tangem

@Suite("TangemPayAccountTokens")
struct TangemPayAccountTokensTests {
    @Test("withdraw starts from the token with the most withdrawable funds; absent amounts count as zero")
    func withdrawStartingPointPicksLargestAmount() {
        // Several compatible entries can't happen until the API goes multichain;
        // the pick rule is guarded for that day.
        let tokens = [
            makeToken(symbol: "USDC", contractAddress: Self.usdcContract, availableForWithdrawal: nil),
            makeToken(symbol: "USDC", contractAddress: Self.usdcContract, availableForWithdrawal: 120.5),
            makeToken(symbol: "USDC", contractAddress: Self.usdcContract, availableForWithdrawal: 3),
        ]

        #expect(tokens.withdrawStartingPoint?.availableForWithdrawal == 120.5)
    }

    @Test("only USDC on Polygon may start a withdraw — the API can't express other tokens or networks")
    func withdrawStartingPointIgnoresRicherUnsupportedTokens() {
        let tokens = [
            makeToken(symbol: "USDC", contractAddress: Self.usdcContract, availableForWithdrawal: 10),
            makeToken(symbol: "USDT", contractAddress: "0xUSDT", availableForWithdrawal: 500),
            // The same USDC contract on the wrong network — only the blockchain check cuts it off.
            makeToken(
                symbol: "USDC",
                contractAddress: Self.usdcContract,
                availableForWithdrawal: 999,
                blockchain: .base(testnet: false)
            ),
        ]

        let pick = tokens.withdrawStartingPoint
        #expect(pick?.tokenItem.blockchain == .polygon(testnet: false))
        #expect(pick?.availableForWithdrawal == 10)
    }

    @Test("funding candidates order canonical-first, then by withdrawable funds — not by BFF order")
    func fundingPriorityPutsCanonicalFirstThenLargestAmount() {
        let tokens = [
            makeToken(symbol: "USDT", contractAddress: "0xUSDT", availableForWithdrawal: 50),
            makeToken(
                symbol: "USDT",
                contractAddress: "0xBASEUSDT",
                availableForWithdrawal: 500,
                blockchain: .base(testnet: false)
            ),
            makeToken(symbol: "USDC", contractAddress: Self.usdcContract, availableForWithdrawal: 3),
        ]

        let ordered = tokens.fundingPriorityOrdered

        #expect(ordered.map(\.availableForWithdrawal) == [3, 500, 50])
        #expect(ordered.first?.tokenItem.blockchain == .polygon(testnet: false))
    }

    @Test("equal withdrawable funds order the same whatever the BFF response order")
    func fundingPriorityBreaksTiesDeterministically() {
        let polygonUSDT = makeToken(symbol: "USDT", contractAddress: "0xUSDT", availableForWithdrawal: 50)
        let baseUSDT = makeToken(
            symbol: "USDT",
            contractAddress: "0xBASEUSDT",
            availableForWithdrawal: 50,
            blockchain: .base(testnet: false)
        )

        let straight = [polygonUSDT, baseUSDT].fundingPriorityOrdered
        let reversed = [baseUSDT, polygonUSDT].fundingPriorityOrdered

        #expect(straight == reversed)
    }

    // MARK: - Helpers

    /// The real Polygon USDC contract, checksummed — the hardcoded one is lowercase,
    /// so the match also proves case-insensitivity.
    private static let usdcContract = "0x3C499c542cEF5E3811e1192ce70d8cC03d5c3359"

    private func makeToken(
        symbol: String,
        contractAddress: String,
        availableForWithdrawal: Decimal?,
        blockchain: Blockchain = .polygon(testnet: false)
    ) -> TangemPayAccountToken {
        TangemPayAccountToken(
            tokenItem: .token(
                Token(
                    name: symbol,
                    symbol: symbol,
                    contractAddress: contractAddress,
                    decimalCount: 6,
                    metadata: .fungibleTokenMetadata
                ),
                BlockchainNetwork(blockchain, derivationPath: nil)
            ),
            depositAddress: "0xDEPOSIT",
            availableForWithdrawal: availableForWithdrawal
        )
    }
}
