//
//  TransactionsListSectionView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemFoundation
import TangemUI
import TangemUIUtils

/// A whole section rendered eagerly. Suitable for short standalone sections only:
/// inside a lazy stack use `TransactionsListSectionHeaderView` and `TransactionsListRowView`
/// directly, otherwise the stack loses per-row laziness and builds the entire section at once.
struct TransactionsListSectionView: View {
    let item: TransactionListItem
    let openTransactionDetailsAction: (TransactionViewModel) -> Void

    var body: some View {
        VStack(spacing: .zero) {
            if item.header.isNotEmpty {
                TransactionsListSectionHeaderView(title: item.header)
            }

            ForEach(item.items, id: \.self) { cellItem in
                TransactionsListRowView(
                    viewModel: cellItem,
                    openTransactionDetailsAction: openTransactionDetailsAction
                )
            }
        }
    }
}

// MARK: - Section header

struct TransactionsListSectionHeaderView: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .style(Font.Tangem.Subheadline.medium, color: .Tangem.Text.Neutral.primary)

            Spacer()
        }
        .padding(.top, .unit(.x6))
        .padding(.bottom, .unit(.x3))
    }
}

// MARK: - Row

struct TransactionsListRowView: View {
    let viewModel: TransactionViewModel
    let openTransactionDetailsAction: (TransactionViewModel) -> Void

    var body: some View {
        SwiftUI.Button {
            FeedbackGenerator.soft()
            openTransactionDetailsAction(viewModel)
        } label: {
            switch viewModel.display.style {
            case .chip:
                TransactionChipRedesigned(viewModel: viewModel)
                    .padding(.vertical, .unit(.x1))
            case .row:
                TransactionViewRedesigned(viewModel: viewModel)
                    .padding(.vertical, .unit(.x3))
            }
        }
        .buttonStyle(.plain)
    }
}
