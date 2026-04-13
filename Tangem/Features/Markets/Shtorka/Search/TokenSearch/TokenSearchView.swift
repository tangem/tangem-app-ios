//
//  TokenSearchView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

// [STUB] Delete this comment when implemented.
//
// TokenSearchView is the redesign-only replacement for the inline search in MarketsMainView.
// It displays search results in two vertical blocks: User Assets (local portfolio) and Market Assets (API).
//
// Screen states (driven by TokenSearchViewModel.screenState):
//   .idle        → show Hints block (last 3 queries) + Recent block (last 3 market transitions)
//   .searching   → show User Assets instantly + shimmer for Market Assets (loading from API)
//   .results     → show User Assets block + Market Assets block, each hidden if empty
//   .empty       → centered stub: "No results found" icon + subtitle
//   .error       → inline error block with "Try again" button (for Market Assets API failure only)
//
// Search field: uses TokenSearchHeaderView (wraps MainBottomSheetHeaderInputView for now,
//   will be swapped to a DS component later — see TokenSearchHeaderView.swift)
//
// Layout order (top to bottom):
//   1. Hints block (only in .idle, max 3 items, hidden when input is non-empty)
//   2. Recent block (only in .idle, max 3 market assets, "Clear All" clears both hints + recents)
//   3. User Assets block (local results, sorted by balance DESC, collapsed to 3 with "Show more")
//   4. Market Assets block (API results, sorted by market cap DESC, all shown)
//
// Keyboard: dismissed on scroll (.scrollDismissesKeyboard(.immediately))
//
// Hidden balances: if app-wide "hide balances" mode is on, User Assets balances show placeholder (BF-03)
//
// Grouped asset tap: when a grouped user asset is tapped, a Bottom Sheet opens showing
//   the Wallet → Account → Network → Asset hierarchy for selection (BF-04).
//   If hidden balances mode is on, balances in this sheet are also masked.
//
// Balance loading states: User Asset rows show different states depending on loading status
//   and cache availability (shimmer, blink, dash, stale icon) — see BF-03 matrix.
//
// See spec: BF-01 (initialization), BF-02 (execution), BF-03 (aggregation),
//   BF-04 (navigation), BF-05 (keyboard), BF-07 (empty), BF-08 (error),
//   BF-09 (hints), BF-10 (recents)
struct TokenSearchView: View {
    @ObservedObject var viewModel: TokenSearchViewModel

    let headerHeight: CGFloat

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .unit(.x4)) {
                // Spacer to clear the overlaid search bar header
                Color.clear
                    .frame(height: headerHeight)

                switch viewModel.screenState {
                case .idle(let content):
                    idleContent(content)

                case .searching:
                    searchingContent

                case .results(let result):
                    resultsContent(result: result)

                case .empty:
                    emptyContent

                case .error:
                    errorContent
                }
            }
        }
        .scrollDismissesKeyboard(.immediately)
    }

    // MARK: - Idle State

    private func idleContent(_ content: TokenSearchScreenState.IdleContent) -> some View {
        TokenSearchRecentsView(
            queries: content.queries,
            marketAssetViewModels: content.marketAssetViewModels,
            onQueryTap: viewModel.onQueryHintTapped,
            onClearAll: viewModel.onClearAllHistory
        )
    }

    // MARK: - Searching State

    private var searchingContent: some View {
        VStack(alignment: .leading, spacing: .unit(.x4)) {
            // [STUB] User Assets block — instant local results
            Text("User Assets (loading...)")
                .style(Font.Tangem.Body16.medium, color: Color.Tangem.Text.Neutral.primary)

            // [STUB] Market Assets shimmer
            Text("Market Assets (shimmer)")
                .style(Font.Tangem.Body16.medium, color: Color.Tangem.Text.Neutral.tertiary)
        }
    }

    // MARK: - Results State

    private func resultsContent(result: TokenSearchResult) -> some View {
        VStack(alignment: .leading, spacing: .unit(.x4)) {
            // [STUB] User Assets block — sorted by balance DESC, collapsed to 3 with "Show more"
            Text("User Assets (\(result.userAssets.count))")
                .style(Font.Tangem.Body16.medium, color: Color.Tangem.Text.Neutral.primary)

            // [STUB] Market Assets block — sorted by market cap DESC
            Text("Market Assets (\(result.marketAssets.count))")
                .style(Font.Tangem.Body16.medium, color: Color.Tangem.Text.Neutral.primary)
        }
    }

    // MARK: - Empty State

    private var emptyContent: some View {
        // [STUB] Centered: "No results found" icon + subtitle
        VStack(spacing: .unit(.x3)) {
            Text("No results found")
                .style(Font.Tangem.Body16.medium, color: Color.Tangem.Text.Neutral.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Error State

    private var errorContent: some View {
        // [STUB] Inline error with "Try again" button (for Market Assets API failure only)
        VStack(spacing: .unit(.x3)) {
            Text("Unable to load data")
                .style(Font.Tangem.Body16.medium, color: Color.Tangem.Text.Neutral.secondary)

            Button("Try again", action: viewModel.onRetryMarketSearch)
        }
    }
}
