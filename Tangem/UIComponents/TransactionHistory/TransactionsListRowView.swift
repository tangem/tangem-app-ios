//
//  TransactionsListRowView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemFoundation

struct TransactionsListRowView: View {
    let viewModel: TransactionViewModel
    let openTransactionDetailsAction: (TransactionViewModel) -> Void

    var body: some View {
        SwiftUI.Button {
            FeedbackGenerator.soft()
            openTransactionDetailsAction(viewModel)
        } label: {
            switch viewModel.display.style {
            case .chip(let style):
                TransactionChip(viewModel: viewModel, style: style)
                    .padding(.vertical, 4)
            case .row:
                TransactionView(viewModel: viewModel)
                    .padding(.vertical, 12)
            }
        }
        .buttonStyle(.plain)
    }
}
