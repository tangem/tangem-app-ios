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

    var body: some View {
        // [STUB] Delete this body when implemented — replace with real search UI.
        ScrollView {
            VStack(alignment: .leading, spacing: SizeUnit.x4.value) {
                switch viewModel.screenState {
                case .idle:
                    idleContent
                case .searching:
                    searchingContent
                case .results:
                    resultsContent
                case .empty:
                    emptyContent
                case .error:
                    errorContent
                }
            }
            .padding(.horizontal, SizeUnit.x4.value)
            .padding(.top, SizeUnit.x4.value)
        }
        .scrollDismissesKeyboard(.immediately)
    }

    // MARK: - Idle State

    private var idleContent: some View {
        VStack(alignment: .leading, spacing: SizeUnit.x4.value) {
            // [STUB] Hints block — last 3 search queries
            Text("Hints")
                .style(Font.Tangem.Body16.medium, color: Color.Tangem.Text.Neutral.secondary)

            // [STUB] Recent block — last 3 market asset transitions
            Text("Recent")
                .style(Font.Tangem.Body16.medium, color: Color.Tangem.Text.Neutral.secondary)
        }
    }

    // MARK: - Searching State

    private var searchingContent: some View {
        VStack(alignment: .leading, spacing: SizeUnit.x4.value) {
            // [STUB] User Assets block — instant local results
            Text("User Assets (loading...)")
                .style(Font.Tangem.Body16.medium, color: Color.Tangem.Text.Neutral.primary)

            // [STUB] Market Assets shimmer
            Text("Market Assets (shimmer)")
                .style(Font.Tangem.Body16.medium, color: Color.Tangem.Text.Neutral.tertiary)
        }
    }

    // MARK: - Results State

    private var resultsContent: some View {
        VStack(alignment: .leading, spacing: SizeUnit.x4.value) {
            // [STUB] User Assets block — sorted by balance DESC, collapsed to 3 with "Show more"
            Text("User Assets (\(viewModel.result?.userAssets.count ?? 0))")
                .style(Font.Tangem.Body16.medium, color: Color.Tangem.Text.Neutral.primary)

            // [STUB] Market Assets block — sorted by market cap DESC
            Text("Market Assets (\(viewModel.result?.marketAssets.count ?? 0))")
                .style(Font.Tangem.Body16.medium, color: Color.Tangem.Text.Neutral.primary)
        }
    }

    // MARK: - Empty State

    private var emptyContent: some View {
        // [STUB] Centered: "No results found" icon + subtitle
        VStack(spacing: SizeUnit.x3.value) {
            Text("No results found")
                .style(Font.Tangem.Body16.medium, color: Color.Tangem.Text.Neutral.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Error State

    private var errorContent: some View {
        // [STUB] Inline error with "Try again" button (for Market Assets API failure only)
        VStack(spacing: SizeUnit.x3.value) {
            Text("Unable to load data")
                .style(Font.Tangem.Body16.medium, color: Color.Tangem.Text.Neutral.secondary)

            Button("Try again", action: viewModel.onRetryMarketSearch)
        }
    }
}
