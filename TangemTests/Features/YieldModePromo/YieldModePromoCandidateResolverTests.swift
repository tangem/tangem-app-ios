//
//  YieldModePromoCandidateResolverTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("YieldModePromoCandidateResolver")
struct YieldModePromoCandidateResolverTests {
    private let resolver = YieldModePromoCandidateResolver()

    @Test("Picks the eligible position with the highest rate")
    func picksHighestRate() {
        let resolution = resolver.resolve(
            positions: [
                position(chainId: 1, address: "0xaaa", balance: .loaded(10), fiat: .loaded(10)),
                position(chainId: 137, address: "0xbbb", balance: .loaded(1), fiat: .loaded(1), symbol: "USDC", network: "Polygon"),
            ],
            markets: [market(chainId: 1, address: "0xaaa", apy: 0.03), market(chainId: 137, address: "0xbbb", apy: 0.05)]
        )

        let expected = YieldModePromoCandidateResolver.Candidate(
            chainId: 137,
            contractAddress: "0xbbb",
            tokenSymbol: "USDC",
            blockchainName: "Polygon",
            apy: 0.05,
            fiatBalance: 1
        )
        #expect(resolution == .candidate(expected))
    }

    @Test("Equal rates go to the larger fiat balance summed across accounts, even on a larger network id")
    func breaksTiesByFiat() {
        let byFiat = resolver.resolve(
            positions: [
                position(chainId: 1, address: "0xaaa", balance: .loaded(1), fiat: .loaded(1)),
                position(chainId: 137, address: "0xccc", balance: .loaded(1), fiat: .loaded(5)),
            ],
            markets: [market(chainId: 1, address: "0xaaa", apy: 0.05), market(chainId: 137, address: "0xccc", apy: 0.05)]
        )
        #expect(candidateAddress(byFiat) == "0xccc")

        let bySummedFiat = resolver.resolve(
            positions: [
                position(chainId: 1, address: "0xaaa", balance: .loaded(1), fiat: .loaded(3)),
                position(chainId: 1, address: "0xaaa", balance: .loaded(1), fiat: .loaded(3)),
                position(chainId: 1, address: "0xbbb", balance: .loaded(1), fiat: .loaded(5)),
            ],
            markets: [market(chainId: 1, address: "0xaaa", apy: 0.05), market(chainId: 1, address: "0xbbb", apy: 0.05)]
        )
        #expect(candidateAddress(bySummedFiat) == "0xaaa")
    }

    @Test("Equal rates and fiat balances go to the smaller network id, then the smaller address in any letter case")
    func breaksTiesByNetworkThenAddress() {
        let byNetwork = resolver.resolve(
            positions: [
                position(chainId: 137, address: "0xaaa", balance: .loaded(1), fiat: .loaded(1)),
                position(chainId: 1, address: "0xbbb", balance: .loaded(1), fiat: .loaded(1)),
            ],
            markets: [market(chainId: 137, address: "0xaaa", apy: 0.05), market(chainId: 1, address: "0xbbb", apy: 0.05)]
        )
        #expect(candidateAddress(byNetwork) == "0xbbb")

        let byAddress = resolver.resolve(
            positions: [
                position(chainId: 1, address: "0xBBB", balance: .loaded(1), fiat: .loaded(1)),
                position(chainId: 1, address: "0xaaa", balance: .loaded(1), fiat: .loaded(1)),
            ],
            markets: [market(chainId: 1, address: "0xBBB", apy: 0.05), market(chainId: 1, address: "0xaaa", apy: 0.05)]
        )
        #expect(candidateAddress(byAddress) == "0xaaa")
    }

    @Test("A catalog rate of 6.1249 reaches the candidate as 6.12")
    func catalogRateReachesCandidate() throws {
        let json = """
        {
          "tokenAddress": "0xaaa", "tokenSymbol": "USDT", "tokenName": "Tether", "apy": 6.1249, "supplyCap": "0",
          "isActive": true, "decimals": 6, "chainId": 1, "chain": "ethereum", "maxFeeNative": null, "maxFeeUSD": null
        }
        """
        let dto = try JSONDecoder().decode(YieldModuleDTO.Response.MarketInfo.self, from: Data(json.utf8))

        let resolution = resolver.resolve(
            positions: [position(chainId: 1, address: "0xaaa", balance: .loaded(1))],
            markets: [YieldModuleMarketInfo(dto: dto, includeIncentive: false)]
        )

        guard case .candidate(let candidate) = resolution else {
            Issue.record("Expected a candidate, got \(resolution)")
            return
        }

        #expect(CommonYieldModePromoAnalyticsLogger.formatAPY(candidate.apy) == "6.12")
    }

    @Test("Positions are matched by network and address, ignoring the address letter case")
    func matchesByChainIdAndAddress() {
        let otherNetwork = resolver.resolve(
            positions: [position(chainId: 137, address: "0xAAA", balance: .loaded(1))],
            markets: [market(chainId: 1, address: "0xaaa", apy: 0.05)]
        )
        #expect(otherNetwork == .noEligibleToken)

        let checksumAddress = resolver.resolve(
            positions: [position(chainId: 1, address: "0xAaA", balance: .loaded(1))],
            markets: [market(chainId: 1, address: "0xaaa", apy: 0.05)]
        )
        #expect(candidateAddress(checksumAddress) == "0xaaa")
    }

    @Test("Inactive catalog entries and zero rates are not offered")
    func skipsInactiveMarketsAndZeroRates() {
        let resolution = resolver.resolve(
            positions: [
                position(chainId: 1, address: "0xaaa", balance: .loaded(1)),
                position(chainId: 1, address: "0xbbb", balance: .loaded(1)),
            ],
            markets: [
                market(chainId: 1, address: "0xaaa", apy: 0.05, isActive: false),
                market(chainId: 1, address: "0xbbb", apy: 0),
            ]
        )

        #expect(resolution == .noEligibleToken)
    }

    @Test("The balance is summed across accounts and must be positive")
    func sumsBalanceAcrossAccounts() {
        let markets = [market(chainId: 1, address: "0xaaa", apy: 0.05)]

        let zero = resolver.resolve(
            positions: [position(chainId: 1, address: "0xaaa", balance: .loaded(0)), position(chainId: 1, address: "0xaaa", balance: .loaded(0))],
            markets: markets
        )
        #expect(zero == .noEligibleToken)

        let positive = resolver.resolve(
            positions: [position(chainId: 1, address: "0xaaa", balance: .loaded(0)), position(chainId: 1, address: "0xaaa", balance: .loaded(2))],
            markets: markets
        )
        #expect(candidateAddress(positive) == "0xaaa")
    }

    @Test("Yield Mode enabled on any position excludes the promo entirely")
    func activeYieldAnywhereExcludes() {
        let resolution = resolver.resolve(
            positions: [
                position(chainId: 1, address: "0xaaa", balance: .loaded(1)),
                position(chainId: 137, address: "0xzzz", balance: .loaded(1), yieldState: .active),
            ],
            markets: [market(chainId: 1, address: "0xaaa", apy: 0.05)]
        )

        #expect(resolution == .noEligibleToken)
    }

    @Test("Waits while a matched position's balance, fiat balance or Yield Mode state is loading")
    func waitsForMatchedPositions() {
        let markets = [market(chainId: 1, address: "0xaaa", apy: 0.05)]

        let balanceLoading = resolver.resolve(
            positions: [position(chainId: 1, address: "0xaaa", balance: .loading)],
            markets: markets
        )
        #expect(balanceLoading == .waiting)

        let stateLoading = resolver.resolve(
            positions: [position(chainId: 1, address: "0xaaa", balance: .loaded(1), yieldState: .loading)],
            markets: markets
        )
        #expect(stateLoading == .waiting)

        let managerBehindCatalog = resolver.resolve(
            positions: [position(chainId: 1, address: "0xaaa", balance: .loaded(1), yieldState: .awaitingMarkets)],
            markets: markets
        )
        #expect(managerBehindCatalog == .waiting)

        let fiatLoading = resolver.resolve(
            positions: [position(chainId: 1, address: "0xaaa", balance: .loaded(1), fiat: .loading)],
            markets: markets
        )
        #expect(fiatLoading == .waiting)
    }

    @Test("A token outside the catalog does not hold the wait while its manager has no market for it")
    func unmatchedAwaitingMarketsDoesNotWait() {
        let resolution = resolver.resolve(
            positions: [
                position(chainId: 1, address: "0xaaa", balance: .loaded(1)),
                position(chainId: 1, address: "0xzzz", balance: .loaded(1), yieldState: .awaitingMarkets),
            ],
            markets: [market(chainId: 1, address: "0xaaa", apy: 0.05)]
        )

        #expect(candidateAddress(resolution) == "0xaaa")
    }

    @Test("An account that failed to refresh makes the data not ready, even on a token outside the catalog")
    func failedAccountIsNotReady() {
        let markets = [market(chainId: 1, address: "0xaaa", apy: 0.05)]

        let sameToken = resolver.resolve(
            positions: [
                position(chainId: 1, address: "0xaaa", balance: .loaded(500)),
                position(chainId: 1, address: "0xaaa", balance: .failed, yieldState: .failed),
            ],
            markets: markets
        )
        #expect(sameToken == .dataNotReady)

        let tokenOutsideCatalog = resolver.resolve(
            positions: [
                position(chainId: 1, address: "0xaaa", balance: .loaded(500)),
                position(chainId: 1, address: "0xzzz", balance: .loaded(1), yieldState: .failed),
            ],
            markets: markets
        )
        #expect(tokenOutsideCatalog == .dataNotReady)
    }

    @Test("A fiat balance without a rate counts as zero instead of holding the wait")
    func fiatWithoutRateCountsAsZero() {
        let resolution = resolver.resolve(
            positions: [
                position(chainId: 1, address: "0xaaa", balance: .loaded(100), fiat: .failed),
                position(chainId: 1, address: "0xbbb", balance: .loaded(1), fiat: .loaded(1)),
            ],
            markets: [market(chainId: 1, address: "0xaaa", apy: 0.05), market(chainId: 1, address: "0xbbb", apy: 0.05)]
        )

        #expect(candidateAddress(resolution) == "0xbbb")
    }

    @Test("An account with Yield Mode disabled for the token does not drop the other accounts")
    func disabledAccountDropsOnlyItsPosition() {
        let resolution = resolver.resolve(
            positions: [
                position(chainId: 1, address: "0xaaa", balance: .loaded(2)),
                position(chainId: 1, address: "0xaaa", balance: .loaded(0), yieldState: .disabled),
            ],
            markets: [market(chainId: 1, address: "0xaaa", apy: 0.05)]
        )

        #expect(candidateAddress(resolution) == "0xaaa")
    }

    @Test("Waits while any position's Yield Mode state is loading, since it may turn out to be enabled")
    func waitsForUnmatchedYieldState() {
        let resolution = resolver.resolve(
            positions: [
                position(chainId: 1, address: "0xaaa", balance: .loaded(1)),
                position(chainId: 137, address: "0xzzz", balance: .loaded(1), yieldState: .loading),
            ],
            markets: [market(chainId: 1, address: "0xaaa", apy: 0.05)]
        )

        #expect(resolution == .waiting)
    }

    @Test("A position whose balance failed does not hold the wait on its Yield Mode state")
    func failedBalanceDoesNotHoldWait() {
        let resolution = resolver.resolve(
            positions: [
                position(chainId: 1, address: "0xaaa", balance: .loaded(1)),
                position(chainId: 1, address: "0xbbb", balance: .failed, fiat: .loading, yieldState: .awaitingMarkets),
                position(chainId: 1, address: "0xccc", balance: .failed, yieldState: .loading),
            ],
            markets: [market(chainId: 1, address: "0xaaa", apy: 0.05), market(chainId: 1, address: "0xbbb", apy: 0.09)]
        )

        #expect(resolution == .dataNotReady)
    }

    @Test("Without matched positions there is nothing to wait for")
    func noMatchedPositionsDoesNotWait() {
        let resolution = resolver.resolve(
            positions: [position(chainId: 1, address: "0xzzz", balance: .loading)],
            markets: [market(chainId: 1, address: "0xaaa", apy: 0.05)]
        )

        #expect(resolution == .noEligibleToken)
    }

    @Test("A balance that failed to load can't rule out Yield Mode enabled, so the data is not ready")
    func failedBalanceIsNotReady() {
        let resolution = resolver.resolve(
            positions: [position(chainId: 1, address: "0xaaa", balance: .failed)],
            markets: [market(chainId: 1, address: "0xaaa", apy: 0.05)]
        )

        #expect(resolution == .dataNotReady)
    }

    @Test("An account without a derivation drops only its own position")
    func missingDerivationDropsOnlyItsPosition() {
        let resolution = resolver.resolve(
            positions: [
                position(chainId: 1, address: "0xaaa", balance: .loaded(2)),
                position(chainId: 1, address: "0xaaa", balance: .missingDerivation, fiat: .missingDerivation, yieldState: .loading),
            ],
            markets: [market(chainId: 1, address: "0xaaa", apy: 0.05)]
        )

        #expect(candidateAddress(resolution) == "0xaaa")
    }

    @Test("Native coins without a contract address are not matched")
    func coinsAreNotMatched() {
        let resolution = resolver.resolve(
            positions: [position(chainId: 1, address: nil, balance: .loaded(1))],
            markets: [market(chainId: 1, address: "0xaaa", apy: 0.05)]
        )

        #expect(resolution == .noEligibleToken)
    }

    // MARK: - Helpers

    private func candidateAddress(_ resolution: YieldModePromoCandidateResolver.Resolution) -> String? {
        guard case .candidate(let candidate) = resolution else {
            return nil
        }

        return candidate.contractAddress
    }

    private func position(
        chainId: Int,
        address: String?,
        balance: YieldModePromoPosition.Balance,
        fiat: YieldModePromoPosition.Balance = .loaded(0),
        symbol: String = "TKN",
        network: String = "Network",
        yieldState: YieldModePromoPosition.YieldState = .notActive
    ) -> YieldModePromoPosition {
        YieldModePromoPosition(
            chainId: chainId,
            contractAddress: address,
            tokenSymbol: symbol,
            blockchainName: network,
            balance: balance,
            fiatBalance: fiat,
            yieldState: yieldState
        )
    }

    private func market(chainId: Int, address: String, apy: Decimal, isActive: Bool = true) -> YieldModuleMarketInfo {
        YieldModuleMarketInfo(
            tokenContractAddress: address,
            apy: apy,
            isActive: isActive,
            chainId: chainId,
            maxFeeNative: nil,
            maxFeeUSD: nil,
            incentive: nil
        )
    }
}
