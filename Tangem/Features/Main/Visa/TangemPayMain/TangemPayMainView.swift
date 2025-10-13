//
//  TangemPayMainView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct TangemPayMainView: View {
    @ObservedObject var viewModel: TangemPayMainViewModel

    var body: some View {
        RefreshScrollView(stateObject: viewModel.refreshScrollViewStateObject) {
            VStack(spacing: 14) {
                MainHeaderView(viewModel: viewModel.mainHeaderViewModel)
                    .fixedSize(horizontal: false, vertical: true)

                if let tangemPayCardDetailsViewModel = viewModel.tangemPayCardDetailsViewModel {
                    TangemPayCardDetailsView(viewModel: tangemPayCardDetailsViewModel)
                }

                TransactionsListView(
                    state: viewModel.tangemPayTransactionHistoryState,
                    exploreAction: nil,
                    exploreTransactionAction: { _ in },
                    reloadButtonAction: viewModel.reloadHistory,
                    isReloadButtonBusy: false,
                    fetchMore: viewModel.fetchNextTransactionHistoryPage()
                )

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .background(Colors.Background.secondary)
    }
}
