//
//  TangemPayAccountTokensTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Foundation
import TangemPay
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

    @Test("withdraw starts from the richest token — the API now expresses any token and network")
    func withdrawStartingPointPicksRichestAcrossNetworks() {
        let tokens = [
            makeToken(symbol: "USDC", contractAddress: Self.usdcContract, availableForWithdrawal: 10, chainId: 137),
            makeToken(symbol: "USDT", contractAddress: "0xUSDT", availableForWithdrawal: 500, chainId: 137),
            makeToken(
                symbol: "USDC",
                contractAddress: Self.usdcContract,
                availableForWithdrawal: 999,
                blockchain: .base(testnet: false),
                chainId: 8453
            ),
        ]

        let pick = tokens.withdrawStartingPoint
        #expect(pick?.tokenItem.blockchain == .base(testnet: false))
        #expect(pick?.availableForWithdrawal == 999)
    }

    @Test("equal withdrawable funds start from the canonical token")
    func withdrawStartingPointBreaksTiesTowardsCanonical() {
        let tokens = [
            makeToken(
                symbol: "USDT",
                contractAddress: "0xBASEUSDT",
                availableForWithdrawal: 50,
                blockchain: .base(testnet: false),
                chainId: 8453
            ),
            makeToken(symbol: "USDC", contractAddress: Self.usdcContract, availableForWithdrawal: 50),
        ]

        #expect(tokens.withdrawStartingPoint?.tokenItem.blockchain == .polygon(testnet: false))
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

    @Test("the canonical token is addressed by its BFF chain id too — the API no longer has a default network")
    func canonicalTokenWithChainIdIsTargeted() {
        let canonical = makeToken(
            symbol: "USDC",
            contractAddress: Self.usdcContract,
            availableForWithdrawal: 10,
            chainId: 137
        )

        #expect(canonical.withdrawEligibility == .targeted(TangemPayWithdrawTarget(
            chainId: 137,
            tokenContractAddress: Self.usdcContract
        )))
    }

    @Test("the account-wide token withdraws untargeted — byte-for-byte the pre-multichain request")
    func accountWideTokenIsEligibleUntargeted() {
        let accountWide = makeToken(
            symbol: "USDC",
            contractAddress: Self.usdcContract,
            availableForWithdrawal: 10
        )

        #expect(accountWide.withdrawEligibility == .untargeted)
    }

    @Test("a non-canonical token is targeted by its BFF chain id and contract")
    func nonCanonicalTokenIsTargeted() {
        let baseUSDC = makeToken(
            symbol: "USDC",
            contractAddress: "0xBASEUSDC",
            availableForWithdrawal: 999,
            blockchain: .base(testnet: false),
            chainId: 8453
        )

        #expect(baseUSDC.withdrawEligibility == .targeted(TangemPayWithdrawTarget(
            chainId: 8453,
            tokenContractAddress: "0xBASEUSDC"
        )))
    }

    @Test("a non-canonical token without a chain id can't be addressed — ineligible, not silently untargeted")
    func nonCanonicalTokenWithoutChainIdIsIneligible() {
        let baseUSDC = makeToken(
            symbol: "USDC",
            contractAddress: "0xBASEUSDC",
            availableForWithdrawal: 999,
            blockchain: .base(testnet: false)
        )

        #expect(baseUSDC.withdrawEligibility == .ineligible)
    }

    @Test("a token the BFF reports without a contract can't be addressed either")
    func tokenWithEmptyContractIsIneligible() {
        let baseUSDC = makeToken(
            symbol: "USDC",
            contractAddress: "",
            availableForWithdrawal: 999,
            blockchain: .base(testnet: false),
            chainId: 8453
        )

        #expect(baseUSDC.withdrawEligibility == .ineligible)
    }

    @Test("withdraw never starts from an ineligible token, whatever its funds")
    func withdrawStartingPointSkipsIneligible() {
        let tokens = [
            makeToken(
                symbol: "USDC",
                contractAddress: "0xBASEUSDC",
                availableForWithdrawal: 999,
                blockchain: .base(testnet: false)
            ),
            makeToken(symbol: "USDT", contractAddress: "0xUSDT", availableForWithdrawal: 5, chainId: 137),
        ]

        #expect(tokens.withdrawStartingPoint?.availableForWithdrawal == 5)
    }

    @Test("only ineligible tokens leave withdraw with no starting point")
    func withdrawStartingPointIsNilWhenAllTokensAreIneligible() {
        let tokens = [
            makeToken(
                symbol: "USDC",
                contractAddress: "0xBASEUSDC",
                availableForWithdrawal: 999,
                blockchain: .base(testnet: false)
            ),
        ]

        #expect(tokens.withdrawStartingPoint == nil)
    }

    @Test("an ineligible token refuses to dispatch rather than withdrawing from the BFF's default network")
    func ineligibleTokenRefusesToDispatch() {
        #expect(throws: (any Error).self) {
            try TangemPayWithdrawEligibility.ineligible.resolveDispatchTarget()
        }
    }

    @Test("an untargeted token dispatches the pre-multichain request")
    func untargetedTokenDispatchesWithoutTarget() throws {
        #expect(try TangemPayWithdrawEligibility.untargeted.resolveDispatchTarget() == nil)
    }

    @Test("a targeted token dispatches its own network and contract")
    func targetedTokenDispatchesItsTarget() throws {
        let target = TangemPayWithdrawTarget(chainId: 8453, tokenContractAddress: "0xBASEUSDC")

        #expect(try TangemPayWithdrawEligibility.targeted(target).resolveDispatchTarget() == target)
    }

    // MARK: - Helpers

    /// The real Polygon USDC contract, checksummed — the hardcoded one is lowercase,
    /// so the match also proves case-insensitivity.
    private static let usdcContract = "0x3C499c542cEF5E3811e1192ce70d8cC03d5c3359"

    private func makeToken(
        symbol: String,
        contractAddress: String,
        availableForWithdrawal: Decimal?,
        blockchain: Blockchain = .polygon(testnet: false),
        chainId: Int? = nil
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
            availableForWithdrawal: availableForWithdrawal,
            chainId: chainId
        )
    }
}
