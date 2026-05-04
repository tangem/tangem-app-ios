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
            .sheet(item: $coordinator.mainTokenDetailsCoordinator) { item in
                // Token details is presented using `.sheet` instead of `.fullScreenCover` due to
                // SwiftUI bug on iOS 26+ (see [REDACTED_INFO]
                NavigationStack {
                    TokenDetailsCoordinatorView(coordinator: item)
                        .toolbar {
                            NavigationToolbarButton.close(
                                placement: .topBarLeading,
                                action: {
                                    dismissMainTokenDetails()
                                }
                            )
                        }
                }
                .tint(Colors.Text.primary1)
            }
    }

    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.tokenDetailsCoordinator) {
                MarketsTokenDetailsCoordinatorView(coordinator: $0)
                    .ignoresSafeArea(.container, edges: .top)
            }
            .navigation(item: $coordinator.marketsSearchCoordinator) {
                MarketsSearchCoordinatorView(coordinator: $0)
                    .ignoresSafeArea(.container, edges: .top) // Keep consistent over-scroll behavior with other pushed screens
            }
            .navigation(item: $coordinator.newsListCoordinator) {
                NewsListCoordinatorView(coordinator: $0)
            }
            .navigation(item: $coordinator.newsPagerViewModel) {
                NewsPagerView(viewModel: $0)
                    .navigationLinks(newsPagerTokenDetailsLink)
            }
            .navigation(item: $coordinator.earnListCoordinator) {
                EarnDetailCoordinatorView(coordinator: $0)
            }
    }

    private var newsPagerTokenDetailsLink: some View {
        NavHolder()
            .navigation(item: $coordinator.newsPagerTokenDetailsCoordinator) {
                MarketsTokenDetailsCoordinatorView(coordinator: $0)
                    .ignoresSafeArea(.container, edges: .top)
            }
    }

    private func dismissMainTokenDetails() {
        coordinator.mainTokenDetailsCoordinator = nil
    }
}
