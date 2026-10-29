//
//  PendingTransactionsListView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemFoundation

struct PendingTransactionsListView: View {
    let items: [TransactionViewModel]
    let exploreTransactionAction: (String) -> Void

    var body: some View {
        if items.isNotEmpty {
            VStack(spacing: .zero) {
                ForEach(items, id: \.self) { item in
                    TransactionsListRowView(viewModel: item) { exploreTransactionAction($0.hash) }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}
