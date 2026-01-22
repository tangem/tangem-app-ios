//
//  LoadingSingleWalletMainContentView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct LoadingSingleWalletMainContentView: View {
    private let viewModel = LoadingSingleWalletMainContentViewModel()
    var body: some View {
        VStack(spacing: 14) {
            ScrollableButtonsView(
                itemsHorizontalOffset: 16,
                buttonsInfo: viewModel.buttonsInfo
            )

            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    SkeletonView()
                        .frame(size: .init(width: 52, height: 12))
                        .cornerRadiusContinuous(3)

                    SkeletonView()
                        .frame(size: .init(width: 70, height: 12))
                        .cornerRadiusContinuous(3)
                }

                Spacer()
            }
            .padding(.vertical, 6)
            .defaultRoundedBackground(with: Colors.Background.primary)

            TransactionsListView(
                state: .loading,
                exploreAction: nil,
                exploreConfirmationDialog: nil,
                exploreTransactionAction: { _ in },
                reloadButtonAction: {},
                isReloadButtonBusy: false,
                fetchMore: nil
            )
        }
        .padding(.horizontal, 16)
    }
}
