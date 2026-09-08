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
}
