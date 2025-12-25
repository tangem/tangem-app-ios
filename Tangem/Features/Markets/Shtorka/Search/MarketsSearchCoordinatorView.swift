//
//  MarketsSearchCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct MarketsSearchCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: MarketsSearchCoordinator

    var body: some View {
        ZStack {
            if let viewModel = coordinator.rootViewModel {
                MarketsSearchView(
                    viewModel: viewModel,
                    onBackButtonAction: coordinator.dismiss
                )
                .navigationLinks(links)
            }

            sheets
        }
        .bindAlert($coordinator.error)
    }

    @ViewBuilder
    var sheets: some View {
        NavHolder()
            .bottomSheet(
                item: $coordinator.marketsListOrderBottomSheetViewModel,
                backgroundColor: Colors.Background.tertiary
            ) {
                MarketsListOrderBottomSheetView(viewModel: $0)
            }
            .floatingSheetContent(for: YieldNoticeViewModel.self) {
                YieldNoticeView(viewModel: $0)
            }
    }

    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.tokenDetailsCoordinator) {
                MarketsTokenDetailsCoordinatorView(coordinator: $0)
                    .ignoresSafeArea(.container, edges: .top) // Without it, the content won't go into the safe area top zone on over-scroll
            }
    }
}
