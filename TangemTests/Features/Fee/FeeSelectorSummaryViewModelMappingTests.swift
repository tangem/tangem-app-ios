//
//  FeeSelectorSummaryViewModelMappingTests.swift
//  TangemTests
//
//  Covers FeeSelectorSummaryViewModel.mapFeeStateToRowViewModel: the insufficient-fee states
//  (.unavailable(.notEnoughFeeBalance) and .unavailable(.noTokenBalance)) must render the
//  "not enough funds" text instead of the dash placeholder ([REDACTED_INFO]), while genuine
//  fee-load errors keep the dash.
//

import Foundation
import Testing
import Combine
import BlockchainSdk
import TangemFoundation
import TangemTestKit
import TangemUI
import TangemLocalization
import TangemAccessibilityIdentifiers
@testable import Tangem

@Suite("FeeSelectorSummaryViewModel — fee state → row mapping")
@MainActor
final class FeeSelectorSummaryViewModelMappingTests: LeakTrackingTestSuite {
    /// A gasless provider pays the fee in the token itself (e.g. USDT), so its fee token is a token.
    private let gaslessTokenFeeToken: TokenItem = .token(
        .init(name: "USDT", symbol: "USDT", contractAddress: "0xUSDT", decimalCount: 6),
        .init(.ethereum(testnet: false), derivationPath: nil)
    )

    // MARK: - Insufficient-fee states ([REDACTED_INFO])

    @Test("Zero gasless-token balance (.noTokenBalance) → 'not enough funds' text, not a dash")
    func noTokenBalanceShowsNotEnoughFundsText() {
        let row = mapRow(state: .unavailable(.noTokenBalance))

        #expect(row.subtitle == .fee(.loaded(text: Localization.gaslessNotEnoughFundsToCoverTokenFee)))
        #expect(row.availability == .unavailable(isSubtitleHighlighted: true))
        #expect(row.subtitleAccessibilityIdentifier == FeeAccessibilityIdentifiers.feeSelectorInsufficientFundsError)
    }

    @Test("Gasless balance below the minimum (.notEnoughFeeBalance) → 'not enough funds' text, not a dash")
    func notEnoughFeeBalanceShowsNotEnoughFundsText() {
        let row = mapRow(state: .unavailable(.notEnoughFeeBalance))

        #expect(row.subtitle == .fee(.loaded(text: Localization.gaslessNotEnoughFundsToCoverTokenFee)))
        #expect(row.availability == .unavailable(isSubtitleHighlighted: true))
        #expect(row.subtitleAccessibilityIdentifier == FeeAccessibilityIdentifiers.feeSelectorInsufficientFundsError)
    }

    @Test("Loaded fee that the balance doesn't cover → 'not enough funds' text")
    func uncoveredFeeShowsNotEnoughFundsText() {
        let row = mapRow(state: .available([:]), feeCoverage: .uncovered(missingAmount: Decimal(string: "0.5")!))

        #expect(row.subtitle == .fee(.loaded(text: Localization.gaslessNotEnoughFundsToCoverTokenFee)))
        #expect(row.subtitleAccessibilityIdentifier == FeeAccessibilityIdentifiers.feeSelectorInsufficientFundsError)
    }

    // MARK: - Non-insufficient states

    @Test("Fee-load error keeps the dash placeholder without the insufficient-funds marker")
    func errorStateShowsDashPlaceholder() {
        let row = mapRow(state: .error(TokenFeeLoaderError.executionReverted))

        #expect(row.subtitle == .fee(.noData))
        #expect(row.availability == .unavailable(isSubtitleHighlighted: false))
        #expect(row.subtitleAccessibilityIdentifier == nil)
    }

    @Test("Loaded fee covered by the balance → available row with a formatted fee subtitle")
    func coveredFeeIsAvailable() {
        let row = mapRow(state: .available([:]), feeCoverage: .covered(feeValue: Decimal(string: "0.5")!))

        #expect(row.availability == .available(isSubtitleHighlighted: false))
        #expect(row.subtitleAccessibilityIdentifier == nil)

        guard case .fee(.loaded) = row.subtitle else {
            Issue.record("Expected a formatted fee subtitle, got \(row.subtitle)")
            return
        }
    }

    // MARK: - Helpers

    private func mapRow(state: TokenFeeProviderState, feeCoverage: FeeCoverage = .undefined) -> FeeSelectorRowViewModel {
        let (sut, feeProvider) = makeSUT()

        return sut.mapFeeStateToRowViewModel(
            state: state,
            feeCoverage: feeCoverage,
            tokenFeeProvider: feeProvider,
            option: .market
        )
    }

    private func makeSUT() -> (sut: FeeSelectorSummaryViewModel, feeProvider: TokenFeeProviderStub) {
        let feeProvider = TokenFeeProviderStub(
            feeTokenItem: gaslessTokenFeeToken,
            initialFee: TokenFee(option: .market, tokenItem: gaslessTokenFeeToken, value: .loading)
        )
        let dataProvider = FeeSelectorDataProviderStub(tokenFeeProvider: feeProvider)
        let sut = FeeSelectorSummaryViewModel(
            tokensDataProvider: dataProvider,
            feesDataProvider: dataProvider,
            feeFormatter: CommonFeeFormatter()
        )

        trackForMemoryLeaks(sut)
        trackForMemoryLeaks(feeProvider)

        return (sut, feeProvider)
    }
}

// MARK: - Data provider stub

private struct FeeSelectorDataProviderStub: FeeSelectorTokensDataProvider, FeeSelectorFeesDataProvider {
    let tokenFeeProvider: TokenFeeProviderStub

    var selectedTokenFeeProvider: TokenFeeProvider { tokenFeeProvider }
    var selectedTokenFeeProviderPublisher: AnyPublisher<TokenFeeProvider, Never> {
        Just<TokenFeeProvider>(tokenFeeProvider).eraseToAnyPublisher()
    }

    var supportedTokenFeeProviders: [any TokenFeeProvider] { [tokenFeeProvider] }
    var supportedTokenFeeProvidersPublisher: AnyPublisher<[any TokenFeeProvider], Never> {
        Just<[any TokenFeeProvider]>([tokenFeeProvider]).eraseToAnyPublisher()
    }

    var selectedTokenFeeOption: FeeOption { .market }
    var selectedTokenFeeOptionPublisher: AnyPublisher<FeeOption, Never> { Just(.market).eraseToAnyPublisher() }
    var feeCoveragePublisher: AnyPublisher<FeeCoverage, Never> { Just(.undefined).eraseToAnyPublisher() }

    var selectorFees: [TokenFee] { [] }
    var selectorFeesPublisher: AnyPublisher<[TokenFee], Never> { Just([]).eraseToAnyPublisher() }
}
