//
//  TokenDetailsCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct TokenDetailsCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: TokenDetailsCoordinator

    init(coordinator: TokenDetailsCoordinator) {
        self.coordinator = coordinator
    }

    var body: some View {
        ZStack {
            if let viewModel = coordinator.tokenDetailsViewModel {
                TokenDetailsView(viewModel: viewModel)
                    .navigationLinks(links)
            }

            sheets
        }
    }

    @ViewBuilder
    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.tokenDetailsCoordinator) {
                TokenDetailsCoordinatorView(coordinator: $0)
            }
    }

    @ViewBuilder
    private var sheets: some View {
        NavHolder()
            .sheet(item: $coordinator.legacySendCoordinator) {
                LegacySendCoordinatorView(coordinator: $0)
            }
            .sheet(item: $coordinator.sendCoordinator) {
                SendCoordinatorView(coordinator: $0)
            }
            .sheet(item: $coordinator.swappingCoordinator) {
                SwappingCoordinatorView(coordinator: $0)
            }
            .sheet(item: $coordinator.modalWebViewModel) {
                WebViewContainer(viewModel: $0)
            }
            .iOS17UIKitSheet(item: $coordinator.expressCoordinator) {
                ExpressCoordinatorView(coordinator: $0)
            }

        NavHolder()
            .bottomSheet(
                item: $coordinator.warningBankCardViewModel,
                sheetContent: {
                    WarningBankCardView(viewModel: $0)
                        .padding(.bottom, 10)
                }
            )
            .bottomSheet(
                item: $coordinator.receiveBottomSheetViewModel,
                settings: .init(backgroundColor: Colors.Background.primary)
            ) {
                ReceiveBottomSheetView(viewModel: $0)
            }
            .bottomSheet(
                item: $coordinator.pendingExpressTxStatusBottomSheetViewModel,
                settings: .init(backgroundColor: Colors.Background.tertiary)
            ) {
                PendingExpressTxStatusBottomSheetView(viewModel: $0)
            }
    }
}
