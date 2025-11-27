//
//  TangemPayTransactionDetailsStateView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization

struct TangemPayTransactionDetailsStateView: View {
    let state: TransactionState

    var body: some View {
        Text(state.title)
            .style(Fonts.Bold.caption1, color: state.color)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(state.color.opacity(0.1))
            .clipShape(Capsule())
    }
}

extension TangemPayTransactionDetailsStateView {
    enum TransactionState {
        case pending
        case declined
        case completed

        var title: String {
            switch self {
            case .pending: Localization.tangemPayStatusPending
            case .declined: Localization.tangemPayStatusDeclined
            case .completed: Localization.tangemPayStatusCompleted
            }
        }

        var color: Color {
            switch self {
            case .pending: Colors.Text.secondary
            case .declined: Colors.Text.warning
            case .completed: Colors.Text.accent
            }
        }
    }
}
