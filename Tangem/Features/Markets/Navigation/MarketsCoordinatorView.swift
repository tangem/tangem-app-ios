//
//  MarketsCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct MarketsCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: MarketsCoordinator

    var body: some View {
        NavigationStack {
            ZStack {
                // [REDACTED_TODO_COMMENT]
                if let marketsViewModel = coordinator.marketsViewModel {
                    MarketsView(viewModel: marketsViewModel)
                        .navigationLinks(links)
                }

                if let mainMarketsViewModel = coordinator.marketsMainViewModel {
                    MarketsMainView(viewModel: mainMarketsViewModel)
                        .navigationLinks(links)
                }

                sheets
            }
            .ignoresSafeArea(.container, edges: .top) // Without it, the content won't go into the safe area top zone on over-scroll
        }
        .tint(Colors.Text.primary1)
    }

    @ViewBuilder
    private var sheets: some View {
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
