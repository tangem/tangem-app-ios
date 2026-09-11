//
//  PortfolioReviewMapperTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import BlockchainSdk
@testable import Tangem

@Suite("PortfolioReviewMapper")
struct PortfolioReviewMapperTests {
    typealias SUT = PortfolioReviewMapper

    private let bitcoin = TokenItem.blockchain(.init(.bitcoin(testnet: false), derivationPath: nil))
    private let ethereum = TokenItem.blockchain(.init(.ethereum(testnet: false), derivationPath: nil))

    @Test("A failed refresh does not block the donut: holdings with values still draw the chart")
    func failedTotalStillDrawsChart() throws {
        let state = map(
            [makeLoadedToken(bitcoin, fiatBalance: 100), makeLoadedToken(ethereum, fiatBalance: 50)],
            totalBalance: .failed(cached: 150, failedItems: [ethereum])
        )

        guard case .loaded(let assets, _, _) = try chart(of: state) else {
            Issue.record("Expected a loaded chart")
            return
        }

        #expect(assets.map(\.name) == [bitcoin.currencySymbol, ethereum.currencySymbol])
    }

    @Test("A total failure with no values anywhere reads as can't load, not as an empty portfolio")
    func failedTotalWithoutValuesShowsCantLoad() throws {
        let state = map(
            [makeUnreachableToken(bitcoin), makeUnreachableToken(ethereum)],
            totalBalance: .failed(cached: nil, failedItems: [bitcoin, ethereum])
        )

        #expect(try chart(of: state) == .noData(.cantLoad))
    }

    @Test("A failed total with nothing to draw still reads as can't load")
    func failedTotalWithoutHoldingsShowsCantLoad() throws {
        let state = map([], totalBalance: .failed(cached: nil, failedItems: []))

        #expect(try chart(of: state) == .noData(.cantLoad))
    }

    /// With and without the Other bucket: the bucket alone no longer makes the share approximate.
    @Test("A share well short of a hundred states itself plainly", arguments: [10, 11])
    func ordinaryShareCarriesNoTilde(assetCount: Int) throws {
        let state = map(makeLoadedTokens(count: assetCount), totalBalance: .loaded(balance: 100))

        guard case .loaded(_, _, let percent) = try chart(of: state) else {
            Issue.record("Expected a loaded chart")
            return
        }

        #expect(!percent.hasPrefix(AppConstants.tildeSign))
    }

    @Test("A bucket holding nothing but a valueless asset leaves the share exact")
    func valuelessBucketKeepsTheShareExact() throws {
        // Deliberately outside `blockchains`, so reordering that list cannot merge this one into the top.
        let unpriced = makeUnreachableToken(.blockchain(.init(.dash(testnet: false), derivationPath: nil)))
        let state = map(makeLoadedTokens(count: 10) + [unpriced], totalBalance: .loaded(balance: 100))

        guard case .loaded(_, _, let percent) = try chart(of: state) else {
            Issue.record("Expected a loaded chart")
            return
        }

        #expect(!percent.hasPrefix(AppConstants.tildeSign))
    }

    @Test("A share that only rounds up to a hundred still says it is approximate")
    func shareRoundedToAHundredStaysApproximate() throws {
        // Ten funded assets plus a dust one: the top covers 99.997%, which the two shown digits print as 100.
        let dust = makeLoadedToken(.blockchain(.init(.dash(testnet: false), derivationPath: nil)), fiatBalance: 3)
        let state = map(makeLoadedTokens(count: 10, balance: 10000) + [dust], totalBalance: .loaded(balance: 100))

        guard case .loaded(_, _, let percent) = try chart(of: state) else {
            Issue.record("Expected a loaded chart")
            return
        }

        let hundred = PercentFormatter().format(1, option: .yield)

        #expect(percent == "\(AppConstants.tildeSign)\(hundred)")
    }
}

// MARK: - Helpers

private extension PortfolioReviewMapperTests {
    func map(_ tokenItems: [TokenItemType], totalBalance: TotalBalanceState) -> PortfolioReviewViewModel.ViewState {
        SUT().map(tokenItems: tokenItems, totalBalance: totalBalance, indicators: [:], timeframe: .day).state
    }

    func chart(of state: PortfolioReviewViewModel.ViewState) throws -> PortfolioReviewViewModel.ViewState.Chart {
        guard case .content(let content) = state else {
            throw TestError.stateIsNotContent(state)
        }

        return content.chart
    }

    /// The top of the ranking holds ten groups, so an eleventh asset is what creates the Other bucket.
    func makeLoadedTokens(count: Int, balance: Decimal = 1) -> [TokenItemType] {
        Self.blockchains.prefix(count).enumerated().map { index, blockchain in
            makeLoadedToken(
                .blockchain(.init(blockchain, derivationPath: nil)),
                fiatBalance: balance * Decimal(count - index)
            )
        }
    }

    func makeLoadedToken(_ tokenItem: TokenItem, fiatBalance: Decimal) -> TokenItemType {
        .default(WalletModelTestsMock(tokenItem: tokenItem, isEmpty: false, fiatBalance: fiatBalance))
    }

    /// A token that has never produced a value: the refresh failed and there is nothing cached.
    func makeUnreachableToken(_ tokenItem: TokenItem) -> TokenItemType {
        .default(WalletModelTestsMock(
            tokenItem: tokenItem,
            isEmpty: false,
            fiatBalanceProvider: MutableTokenBalanceProviderMock(initialState: .failure(.none))
        ))
    }

    enum TestError: Error {
        case stateIsNotContent(PortfolioReviewViewModel.ViewState)
    }

    static let blockchains: [Blockchain] = [
        .bitcoin(testnet: false),
        .ethereum(testnet: false),
        .cosmos(testnet: false),
        .solana(curve: .ed25519, testnet: false),
        .alephium(testnet: false),
        .polygon(testnet: false),
        .avalanche(testnet: false),
        .tron(testnet: false),
        .litecoin,
        .dogecoin,
        .kaspa(testnet: false),
    ]
}
