//
//  EarnOpportunitiesMapperTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemLocalization
import TangemUI
import BlockchainSdk
@testable import Tangem

@Suite("EarnOpportunitiesMapper")
struct EarnOpportunitiesMapperTests {
    typealias SUT = EarnOpportunitiesMapper

    static let supportedBlockchains: Set<Blockchain> = [
        .cosmos(testnet: false),
        .solana(curve: .ed25519, testnet: false),
        .ethereum(testnet: false),
        .bitcoin(testnet: false),
    ]

    // MARK: - Variant selection

    @Test("Nothing earn-eligible shows suggestions headed by the best rate")
    func nothingEligibleShowsSuggestions() throws {
        let accounts = [makeAccount(holdings: [makeHolding(crypto: 0, fiat: 0, isActive: false)])]
        let atomSuggestion = makeSuggestion(id: "atom")
        let solSuggestion = makeSuggestion(id: "sol")
        let suggestions = [atomSuggestion, solSuggestion]
        let state = map(accounts: accounts, suggestions: .loaded(suggestions))
        let content = try content(of: state)
        let rows = try content.suggestions()

        #expect(rows.map(\.id) == ["atom_cosmos_Staking", "sol_cosmos_Staking"])
        let subtitle = try #require(content.subtitle)
        _ = try #require(subtitle.chip)
        _ = try #require(subtitle.suffix)
    }

    @Test("All eligible tokens already active shows suggestions minus the active assets")
    func allActiveFiltersOwnedAssets() throws {
        let accounts = [makeAccount(holdings: [makeHolding(currencyId: "cosmos", networkId: "cosmos", isActive: true)])]
        let atomSuggestion = makeSuggestion(id: "atom", networkId: "cosmos")
        let solSuggestion = makeSuggestion(id: "sol", networkId: "solana")
        let suggestions = [atomSuggestion, solSuggestion]
        let state = map(accounts: accounts, suggestions: .loaded(suggestions))
        let content = try content(of: state)
        let rows = try content.suggestions()

        #expect(rows.map(\.id) == ["sol_solana_Staking"])
        #expect(content.subtitle?.chip == nil)
    }

    @Test("Asset active on one network is still suggested on another network")
    func activeAssetOnOtherNetworkIsSuggested() throws {
        let accounts = [makeAccount(holdings: [makeHolding(currencyId: "usdc", networkId: "ethereum", isActive: true)])]
        let state = map(accounts: accounts, suggestions: .loaded([makeSuggestion(id: "usdc", networkId: "solana")]))
        let rows = try content(of: state).suggestions()

        #expect(rows.map(\.id) == ["usdc_solana_Staking"])
        #expect(rows.first?.productText == Localization.commonStaking)
    }

    @Test("Eligible non-active holdings show accounts with rewards")
    func eligibleHoldingsShowAccounts() throws {
        let accounts = [makeAccount(holdings: [makeHolding(fiat: 100, apy: 0.05)])]
        let state = map(accounts: accounts, suggestions: .loaded([makeSuggestion()]))
        let content = try content(of: state)
        let items = try content.accounts()

        #expect(items.count == 1)
        // Reward amount is fiat 100 × apy 0.05 = 5; the view adds the "+ …/year" template.
        let token = try #require(items.first?.tokens.first)
        #expect(token.rewardAmount == BalanceFormatter().formatFiatBalance(5))
        _ = try #require(content.subtitle?.chip)
        #expect(content.subtitle?.suffix == nil)
    }

    // MARK: - Eligibility

    @Test("Zero-balance non-active holding is dropped, active zero-balance stays")
    func zeroBalanceEligibility() throws {
        let accountOne = makeAccount(id: "a", holdings: [makeHolding(crypto: 0, fiat: 0, isActive: false)])
        let accountTwo = makeAccount(id: "b", holdings: [makeHolding(crypto: 0, fiat: 0, isActive: true)])
        let accounts = [accountOne, accountTwo]
        let state = map(accounts: accounts, suggestions: .loaded([makeSuggestion()]))
        // Account "a" has nothing eligible; "b" keeps its active token → all-active suggestions variant.
        let content = try content(of: state)
        _ = try content.suggestions()

        // Discriminates all-active (chip nil) from the nothing-eligible fallback (chip = rate), which
        // would also be .suggestions — otherwise a broken `|| apyInfo.isActive` clause would slip through.
        #expect(content.subtitle?.chip == nil)
    }

    @Test("Active tokens are hidden from the rewards list and its sum, accounts left empty by that are dropped")
    func activeTokensHiddenFromRewardsList() throws {
        let activeHolding = makeHolding(id: "active", currencyId: "active", fiat: 1000, apy: 0.10, isActive: true)
        let idleHolding = makeHolding(id: "idle", currencyId: "idle", fiat: 100, apy: 0.05)
        let mixedAccount = makeAccount(id: "mixed", holdings: [activeHolding, idleHolding])
        let workingHolding = makeHolding(id: "working", currencyId: "working", isActive: true)
        let allActiveAccount = makeAccount(id: "allActive", holdings: [workingHolding])
        let accounts = [mixedAccount, allActiveAccount]
        let state = map(accounts: accounts)
        let content = try content(of: state)
        let items = try content.accounts()

        #expect(items.map(\.id) == ["mixed"])
        #expect(items.first?.tokens.map(\.id) == ["idle"])
        // Sum counts only the idle token (5), not the active one (100).
        #expect(content.subtitle?.chip == .fiat(BalanceFormatter().formatFiatBalance(5)))
    }

    @Test("Tokens inside an account are sorted by potential reward, descending")
    func tokensSortedByRewardInsideAccount() throws {
        let smallHolding = makeHolding(id: "small", currencyId: "small", fiat: 100, apy: 0.01)
        let bigHolding = makeHolding(id: "big", currencyId: "big", fiat: 1000, apy: 0.10)
        let accounts = [makeAccount(holdings: [smallHolding, bigHolding])]
        let state = map(accounts: accounts)
        let items = try content(of: state).accounts()

        #expect(items.first?.tokens.map(\.id) == ["big", "small"])
    }

    @Test("Accounts are sorted by potential reward, descending")
    func accountsSortedByReward() throws {
        let smallAccount = makeAccount(id: "small", holdings: [makeHolding(fiat: 100, apy: 0.01)])
        let bigAccount = makeAccount(id: "big", holdings: [makeHolding(fiat: 1000, apy: 0.10)])
        let accounts = [smallAccount, bigAccount]
        let state = map(accounts: accounts)
        let items = try content(of: state).accounts()

        #expect(items.map(\.id) == ["big", "small"])
    }

    @Test("Account display is capped at five, the header sum still counts the hidden ones")
    func accountsCappedAtFiveSumCountsAll() throws {
        let accounts = (0 ..< 7).map { index in
            makeAccount(
                id: "acc\(index)",
                holdings: [makeHolding(id: "t\(index)", currencyId: "t\(index)", fiat: Decimal(100 * (index + 1)), apy: 0.1)]
            )
        }
        let state = map(accounts: accounts)
        let content = try content(of: state)
        let items = try content.accounts()

        #expect(items.count == 5)
        #expect(items.first?.id == "acc6")
        #expect(!items.map(\.id).contains("acc1"))
        #expect(!items.map(\.id).contains("acc0"))

        // 100+200+...+700 = 2800, ×0.1 = 280 — includes the two accounts hidden by the cap.
        #expect(content.subtitle?.chip == .fiat(BalanceFormatter().formatFiatBalance(280)))
    }

    @Test("Mapper leaves accounts expanded; collapsing is applied by the view model")
    func mapperLeavesAccountsExpanded() throws {
        let accounts = [makeAccount(id: "acc", holdings: [makeHolding()])]
        let state = map(accounts: accounts)
        let items = try content(of: state).accounts()

        #expect(items.first?.isExpanded == true)
    }

    // MARK: - Suggestions loading and limits

    @Test("Suggestions still loading in a suggestions variant keeps the skeleton")
    func suggestionsLoadingKeepsSkeleton() {
        let state = map(suggestions: .loading)

        #expect(state == .loading)
    }

    @Test("Failed suggestions in a suggestions variant show empty content without the rate headline")
    func suggestionsFailureShowsEmptyContent() throws {
        let state = map(suggestions: .failed)
        let content = try content(of: state)
        let rows = try content.suggestions()

        #expect(rows.isEmpty)
        #expect(content.subtitle == nil)
    }

    @Test("All tokens active while suggestions still load keeps the skeleton")
    func allActiveSuggestionsLoadingKeepsSkeleton() {
        let accounts = [makeAccount(holdings: [makeHolding(currencyId: "cosmos", networkId: "cosmos", isActive: true)])]
        let state = map(accounts: accounts, suggestions: .loading)

        #expect(state == .loading)
    }

    @Test("All tokens active but suggestions failed: empty list keeps the all-active subtitle")
    func allActiveSuggestionsFailureKeepsSubtitle() throws {
        let accounts = [makeAccount(holdings: [makeHolding(currencyId: "cosmos", networkId: "cosmos", isActive: true)])]
        let state = map(accounts: accounts, suggestions: .failed)
        let content = try content(of: state)
        let rows = try content.suggestions()

        #expect(rows.isEmpty)
        #expect(content.subtitle?.chip == nil)
        #expect(content.subtitle?.prefix == Localization.forYouEarnOpportunitiesAllTokensActive)
        #expect(content.subtitle?.suffix == nil)
    }

    @Test("Rates still resolving with nothing eligible keeps the skeleton")
    func resolvingRatesKeepsSkeleton() {
        let state = map(suggestions: .loaded([makeSuggestion()]), isResolvingRates: true)

        #expect(state == .loading)
    }

    @Test("Eligible holdings show up even while other rates are still resolving")
    func eligibleHoldingsShowDespiteResolvingRates() throws {
        let accounts = [makeAccount(holdings: [makeHolding()])]
        let state = map(accounts: accounts, suggestions: .loading, isResolvingRates: true)
        let items = try content(of: state).accounts()

        #expect(items.count == 1)
    }

    @Test("Suggestions are capped at five after filtering out active assets")
    func suggestionsCappedAfterFiltering() throws {
        let accounts = [makeAccount(holdings: [makeHolding(currencyId: "token0", networkId: "net", isActive: true)])]
        let suggestions = (0 ..< 8).map { makeSuggestion(id: "token\($0)", networkId: "net") }
        let state = map(accounts: accounts, suggestions: .loaded(suggestions))
        let rows = try content(of: state).suggestions()

        #expect(rows.count == 5)
        #expect(!rows.map(\.id).contains("token0_net_Staking"))
    }

    // MARK: - New-logic coverage

    @Test("Holding with a crypto balance but no fiat rate is still eligible")
    func cryptoBalanceWithoutRateIsEligible() throws {
        let accounts = [makeAccount(holdings: [makeHolding(crypto: 1, fiat: nil, isActive: false)])]
        let state = map(accounts: accounts, suggestions: .loaded([makeSuggestion()]))
        let items = try content(of: state).accounts()

        #expect(items.count == 1)
    }

    @Test("Zero crypto balance is dropped even with a fiat rate present")
    func zeroCryptoWithFiatIsIneligible() throws {
        let accounts = [makeAccount(holdings: [makeHolding(crypto: 0, fiat: 100, isActive: false)])]
        let state = map(accounts: accounts, suggestions: .loaded([makeSuggestion()]))
        // Filtered out → falls through to the suggestions variant (an accounts variant would make .suggestions() throw).
        let rows = try content(of: state).suggestions()

        #expect(rows.map(\.id) == ["atom_cosmos_Staking"])
    }

    @Test("Eligible holding with crypto balance but no fiat rate carries no reward, APY stays")
    func fiatlessHoldingHasNoRewardButKeepsApy() throws {
        let accounts = [makeAccount(holdings: [makeHolding(crypto: 5, fiat: nil, apy: 0.05, isActive: false)])]
        let state = map(accounts: accounts, suggestions: .loaded([makeSuggestion()]))
        let items = try content(of: state).accounts()
        let token = try #require(items.first?.tokens.first)

        #expect(token.rewardAmount == nil)
        #expect(token.apyText == PercentFormatter().format(0.05, option: .staking))
    }

    @Test("Best-rate subtitle chip is the suggestion's rateText verbatim")
    func bestRateSubtitleChipUsesRateText() throws {
        let accounts = [makeAccount(holdings: [makeHolding(crypto: 0, fiat: 0, isActive: false)])]
        let state = map(accounts: accounts, suggestions: .loaded([makeSuggestion(id: "atom")]))
        let content = try content(of: state)
        _ = try content.suggestions()

        #expect(content.subtitle?.chip == .rate("APY 14.00 %"))
    }

    @Test("Best-rate subtitle takes the first (top) suggestion's rate, not another")
    func bestRateSubtitleUsesFirstSuggestion() throws {
        let accounts = [makeAccount(holdings: [makeHolding(crypto: 0, fiat: 0, isActive: false)])]
        let topSuggestion = makeSuggestion(id: "a", rateText: "APY 20.00 %")
        let lowerSuggestion = makeSuggestion(id: "b", rateText: "APY 5.00 %")
        let suggestions = [topSuggestion, lowerSuggestion]
        let state = map(accounts: accounts, suggestions: .loaded(suggestions))
        let content = try content(of: state)
        _ = try content.suggestions()

        #expect(content.subtitle?.chip == .rate("APY 20.00 %"))
    }

    @Test("Suggestion API id differing from the holding's domain currencyId still matches after resolution")
    func suggestionMatchesHoldingViaResolvedCurrencyId() throws {
        // ATOM is the Cosmos native coin: its resolved domain currencyId is "cosmos", not the API id "atom".
        let accounts = [makeAccount(holdings: [makeHolding(currencyId: "cosmos", networkId: "cosmos", isActive: true)])]
        let state = map(accounts: accounts, suggestions: .loaded([makeSuggestion(id: "atom", networkId: "cosmos")]))
        let rows = try content(of: state).suggestions()

        #expect(rows.isEmpty)
    }

    @Test("Suggestion on an unsupported network falls back to raw id matching")
    func unsupportedNetworkFallsBackToRawMatching() throws {
        let accounts = [makeAccount(holdings: [makeHolding(currencyId: "foo", networkId: "unsupported-net", isActive: true)])]
        let fooSuggestion = makeSuggestion(id: "foo", networkId: "unsupported-net")
        let barSuggestion = makeSuggestion(id: "bar", networkId: "unsupported-net")
        let suggestions = [fooSuggestion, barSuggestion]
        let state = map(accounts: accounts, suggestions: .loaded(suggestions))
        let rows = try content(of: state).suggestions()

        #expect(rows.map(\.name) == ["bar"])
    }

    @Test("All active with every suggestion filtered out: empty list keeps the all-active subtitle")
    func allActiveFilteredToEmptyKeepsSubtitle() throws {
        let accounts = [makeAccount(holdings: [makeHolding(currencyId: "cosmos", networkId: "cosmos", isActive: true)])]
        let state = map(accounts: accounts, suggestions: .loaded([makeSuggestion(id: "atom", networkId: "cosmos")]))
        let content = try content(of: state)
        let rows = try content.suggestions()

        #expect(rows.isEmpty)
        #expect(content.subtitle?.chip == nil)
        #expect(content.subtitle?.prefix == Localization.forYouEarnOpportunitiesAllTokensActive)
        #expect(content.subtitle?.suffix == nil)
    }

    @Test("Yield-mode suggestion row id carries the yield-mode suffix")
    func yieldModeSuggestionIdSuffix() throws {
        let accounts = [makeAccount(holdings: [makeHolding(crypto: 0, fiat: 0, isActive: false)])]
        let state = map(accounts: accounts, suggestions: .loaded([makeSuggestion(id: "aave", type: .yieldMode)]))
        let rows = try content(of: state).suggestions()

        #expect(rows.first?.id.hasSuffix("_\(EarnType.yieldMode.rawValue)") == true)
        #expect(rows.first?.productText == Localization.commonYieldMode)
    }
}

// MARK: - State unwrapping

private extension EarnOpportunitiesViewModel.ViewState.Content {
    func accounts() throws -> [EarnAccountListItem] {
        guard case .accounts(let items) = list else {
            throw EarnOpportunitiesMapperTests.TestError.unexpectedList(list)
        }

        return items
    }

    func suggestions() throws -> [EarnSuggestionRowData] {
        guard case .suggestions(let rows) = list else {
            throw EarnOpportunitiesMapperTests.TestError.unexpectedList(list)
        }

        return rows
    }
}

// MARK: - Fixtures

private extension EarnOpportunitiesMapperTests {
    func map(
        accounts: [EarnOpportunitiesMapper.AccountCandidate] = [],
        suggestions: EarnOpportunitiesMapper.SuggestionsState = .loaded([]),
        isResolvingRates: Bool = false
    ) -> EarnOpportunitiesViewModel.ViewState {
        SUT(supportedBlockchains: Self.supportedBlockchains)
            .map(accounts: accounts, suggestions: suggestions, isResolvingRates: isResolvingRates)
    }

    func content(of state: EarnOpportunitiesViewModel.ViewState) throws -> EarnOpportunitiesViewModel.ViewState.Content {
        guard case .content(let content) = state else {
            throw TestError.notContent
        }

        return content
    }

    enum TestError: Error {
        case notContent
        case unexpectedList(EarnOpportunitiesViewModel.ViewState.List)
    }

    func makeAccount(id: String = "account", holdings: [EarnOpportunitiesMapper.HoldingCandidate]) -> EarnOpportunitiesMapper.AccountCandidate {
        EarnOpportunitiesMapper.AccountCandidate(
            id: id,
            name: id,
            icon: AccountModel.CompositeIcon(name: .star, color: .azure),
            holdings: holdings
        )
    }

    func makeHolding(
        id: String = "btc",
        currencyId: String = "btc",
        networkId: String = "bitcoin",
        crypto: Decimal? = 100,
        fiat: Decimal? = 100,
        apy: Decimal = 0.05,
        isActive: Bool = false
    ) -> EarnOpportunitiesMapper.HoldingCandidate {
        EarnOpportunitiesMapper.HoldingCandidate(
            id: id,
            assetKey: EarnOpportunitiesMapper.AssetKey(currencyId: currencyId, networkId: networkId),
            tokenIconInfo: TokenIconInfo(
                name: id,
                blockchainIconAsset: nil,
                imageURL: nil,
                isCustom: false,
                customTokenColor: nil
            ),
            currencyName: id,
            networkName: networkId,
            cryptoBalance: crypto,
            fiatBalance: fiat,
            apyInfo: EarnApyInfo(isActive: isActive, apy: apy, product: .staking)
        )
    }

    func makeSuggestion(
        id: String = "atom",
        networkId: String = "cosmos",
        apy: Decimal = 0.14,
        rateText: String = "APY 14.00 %",
        type: EarnType = .staking
    ) -> EarnTokenModel {
        EarnTokenModel(
            id: id,
            name: id,
            symbol: id.uppercased(),
            imageUrl: nil,
            networkId: networkId,
            networkName: networkId,
            blockchainIconAsset: nil,
            contractAddress: nil,
            decimalCount: nil,
            rateValue: apy,
            rateType: .apy,
            rateText: rateText,
            earnType: type
        )
    }
}
