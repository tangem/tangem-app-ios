//
//  EarnOpportunitiesMapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation

/// Picks the section variant and aggregates its contents; `RowBuilder` renders them.
struct EarnOpportunitiesMapper {
    typealias ViewState = EarnOpportunitiesViewModel.ViewState

    private let rowBuilder = RowBuilder()
    private let tokenItemMapper: TokenItemMapper

    init(supportedBlockchains: Set<Blockchain> = SupportedBlockchains.all) {
        tokenItemMapper = TokenItemMapper(supportedBlockchains: supportedBlockchains)
    }

    func map(
        accounts: [AccountCandidate],
        suggestions: SuggestionsState,
        isResolvingRates: Bool
    ) -> ViewState {
        let eligibleAccounts = accounts.filteringHoldings(\.isEarnEligible)

        guard eligibleAccounts.isNotEmpty else {
            return makeNothingEligibleState(
                suggestions: suggestions,
                isResolvingRates: isResolvingRates
            )
        }

        let holdings = eligibleAccounts.flatMap(\.holdings)

        guard holdings.contains(where: { !$0.apyInfo.isActive }) else {
            return makeEverythingActiveState(holdings: holdings, suggestions: suggestions)
        }

        return makePotentialRewardsState(eligibleAccounts)
    }
}

// MARK: - Variant picking

private extension EarnOpportunitiesMapper {
    /// Nothing eligible: suggestions, or the skeleton while rates still load.
    func makeNothingEligibleState(suggestions: SuggestionsState, isResolvingRates: Bool) -> ViewState {
        guard !isResolvingRates else {
            return .loading
        }

        return makeSuggestionsState(suggestions, excluding: [], subtitle: .bestSuggestionRate)
    }

    /// Everything already earns: suggest what the user doesn't hold yet.
    func makeEverythingActiveState(holdings: [HoldingCandidate], suggestions: SuggestionsState) -> ViewState {
        let activeKeys = Set(holdings.map(\.assetKey))

        return makeSuggestionsState(suggestions, excluding: activeKeys, subtitle: .allTokensActive)
    }
}

// MARK: - Potential rewards variant

private extension EarnOpportunitiesMapper {
    func makePotentialRewardsState(_ accounts: [AccountCandidate]) -> ViewState {
        // Active tokens are hidden from rows and sums; they only drive variant choice and filtering.
        let inactiveAccounts = accounts.filteringHoldings { !$0.apyInfo.isActive }

        let items = inactiveAccounts
            .map { account in
                (account: account.sortingHoldingsByReward(), reward: account.potentialReward)
            }
            .sorted { $0.reward > $1.reward }
            .prefix(Constants.displayLimit)
            .map { account, reward in
                rowBuilder.makeAccountItem(account, reward: reward)
            }

        let totalReward = inactiveAccounts.sum(by: \.potentialReward)

        return .content(.init(
            subtitle: rowBuilder.makeRewardsSubtitle(totalReward: totalReward),
            list: .accounts(items)
        ))
    }
}

// MARK: - Suggestion variants

private extension EarnOpportunitiesMapper {
    enum SuggestionSubtitle {
        /// "Get up to {APY x%} annually".
        case bestSuggestionRate
        /// "All your assets are at work, explore new opportunities".
        case allTokensActive
    }

    func makeSuggestionsState(
        _ suggestions: SuggestionsState,
        excluding activeKeys: Set<AssetKey>,
        subtitle: SuggestionSubtitle
    ) -> ViewState {
        guard case .loaded(let tokens) = suggestions else {
            // Skeleton until the one-shot fetch settles; failure → empty list.
            return suggestions == .loading ? .loading : makeEmptySuggestionsState(subtitle)
        }

        let visible = tokens
            .filter { !activeKeys.contains(suggestionAssetKey($0)) }
            .prefix(Constants.displayLimit)

        guard let best = visible.first else {
            return makeEmptySuggestionsState(subtitle)
        }

        return .content(.init(
            subtitle: makeSubtitle(subtitle, best: best),
            list: .suggestions(visible.map(rowBuilder.makeSuggestionRow))
        ))
    }

    func makeEmptySuggestionsState(_ subtitle: SuggestionSubtitle) -> ViewState {
        .content(.init(
            subtitle: makeSubtitle(subtitle, best: nil),
            list: .suggestions([])
        ))
    }

    func makeSubtitle(_ subtitle: SuggestionSubtitle, best: EarnTokenModel?) -> EarnRewardSubtitle? {
        switch subtitle {
        case .allTokensActive:
            rowBuilder.makeAllActiveSubtitle()
        case .bestSuggestionRate:
            rowBuilder.makeBestRateSubtitle(best: best)
        }
    }
}

// MARK: - Constants

private extension EarnOpportunitiesMapper {
    enum Constants {
        /// Row cap; the header sum still counts items hidden by it.
        static let displayLimit = 5
    }
}

// MARK: - Aggregation helpers

private extension Array where Element == EarnOpportunitiesMapper.AccountCandidate {
    /// Drops accounts left with no matching holdings.
    func filteringHoldings(
        _ isIncluded: (EarnOpportunitiesMapper.HoldingCandidate) -> Bool
    ) -> [EarnOpportunitiesMapper.AccountCandidate] {
        compactMap { account in
            let holdings = account.holdings.filter(isIncluded)
            guard holdings.isNotEmpty else {
                return nil
            }

            return Element(id: account.id, name: account.name, icon: account.icon, holdings: holdings)
        }
    }
}

private extension EarnOpportunitiesMapper.AccountCandidate {
    func sortingHoldingsByReward() -> Self {
        Self(
            id: id,
            name: name,
            icon: icon,
            holdings: holdings.sorted { $0.potentialReward > $1.potentialReward }
        )
    }
}

// MARK: - Suggestion matching

private extension EarnOpportunitiesMapper {
    /// Built from the same domain `tokenItem` as holdings, so matching can't desync on API id/network formatting.
    func suggestionAssetKey(_ token: EarnTokenModel) -> AssetKey {
        let network = NetworkModel(
            networkId: token.networkId,
            contractAddress: token.contractAddress,
            decimalCount: token.decimalCount
        )

        guard let tokenItem = tokenItemMapper.mapToTokenItem(
            id: token.id,
            name: token.name,
            symbol: token.symbol,
            network: network
        ) else {
            return AssetKey(currencyId: token.id, networkId: token.networkId)
        }

        return AssetKey(currencyId: tokenItem.currencyId ?? token.id, networkId: tokenItem.networkId)
    }
}
