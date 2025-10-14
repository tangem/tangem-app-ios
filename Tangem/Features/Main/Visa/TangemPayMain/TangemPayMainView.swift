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
                VStack(spacing: .zero) {
                    MainHeaderView(viewModel: viewModel.mainHeaderViewModel)
                        .fixedSize(horizontal: false, vertical: true)

                    ScrollableButtonsView(
                        itemsHorizontalOffset: 14,
                        itemsVerticalOffset: 3,
                        buttonsInfo: [
                            // [REDACTED_TODO_COMMENT]
                            FixedSizeButtonWithIconInfo(
                                title: "Receive",
                                icon: Assets.arrowDownMini,
                                disabled: false,
                                action: viewModel.addFunds
                            ),
                        ]
                    )
                    .padding(.horizontal, 14)
                    .padding(.bottom, 14)
                }
                .background(Colors.Background.primary)
                .cornerRadiusContinuous(14)

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
        .floatingSheetContent(for: ReceiveMainViewModel.self) {
            ReceiveMainView(viewModel: $0)
        }
        .floatingSheetContent(for: TangemPayNoDepositAddressSheetViewModel.self) {
            BottomSheetErrorContentView(
                title: $0.title,
                subtitle: $0.subtitle,
                closeAction: $0.close,
                primaryButton: $0.primaryButtonSettings
            )
            .floatingSheetConfiguration { configuration in
                configuration.backgroundInteractionBehavior = .tapToDismiss
            }
        }
    }
}
