//
//  TangemPayTransactionHistoryView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemFoundation

struct TangemPayTransactionHistoryView: View {
    let state: TransactionsListView.State
    let visibleBodyHeight: CGFloat
    let headerHeight: CGFloat
    let fetchMore: FetchMore?
    let reloadAction: () -> Void
    let openTransactionDetailsAction: (String) -> Void

    var body: some View {
        switch state {
        case .error:
            TangemPayTransactionHistoryErrorView(reloadAction: reloadAction)
                .frame(maxWidth: .infinity, minHeight: max(0, visibleBodyHeight - headerHeight), alignment: .center)
                .frame(maxWidth: .infinity, minHeight: visibleBodyHeight, alignment: .top)
        case .loading, .loaded, .notSupported:
            TransactionsListView(
                state: state,
                exploreAction: nil,
                openTransactionDetailsAction: { openTransactionDetailsAction($0.hash) },
                reloadButtonAction: reloadAction,
                isReloadButtonBusy: false,
                fetchMore: fetchMore
            )
            .frame(maxWidth: .infinity, minHeight: visibleBodyHeight, alignment: .top)
        }
    }
}

// MARK: - Previews

#Preview("Loading") {
    TangemPayTransactionHistoryView(
        state: .loading,
        visibleBodyHeight: 600,
        headerHeight: 0,
        fetchMore: nil,
        reloadAction: {},
        openTransactionDetailsAction: { _ in }
    )
    .padding(.horizontal, 16)
    .frame(maxHeight: .infinity, alignment: .top)
    .background(DesignSystem.Color.bgPrimary)
}

#Preview("Empty") {
    TangemPayTransactionHistoryView(
        state: .loaded([]),
        visibleBodyHeight: 600,
        headerHeight: 0,
        fetchMore: nil,
        reloadAction: {},
        openTransactionDetailsAction: { _ in }
    )
    .padding(.horizontal, 16)
    .frame(maxHeight: .infinity, alignment: .top)
    .background(DesignSystem.Color.bgPrimary)
}

#Preview("Error") {
    TangemPayTransactionHistoryView(
        state: .error("Preview"),
        visibleBodyHeight: 600,
        headerHeight: 0,
        fetchMore: nil,
        reloadAction: {},
        openTransactionDetailsAction: { _ in }
    )
    .padding(.horizontal, 16)
    .frame(maxHeight: .infinity, alignment: .top)
    .background(DesignSystem.Color.bgPrimary)
}

#if DEBUG
#Preview("Loaded") {
    TangemPayTransactionHistoryView(
        state: .loaded([TransactionListItem(header: "Today", items: TransactionViewPreviewData.figmaViewModels1)]),
        visibleBodyHeight: 600,
        headerHeight: 0,
        fetchMore: nil,
        reloadAction: {},
        openTransactionDetailsAction: { _ in }
    )
    .padding(.horizontal, 16)
    .frame(maxHeight: .infinity, alignment: .top)
    .background(DesignSystem.Color.bgPrimary)
}
#endif // DEBUG
