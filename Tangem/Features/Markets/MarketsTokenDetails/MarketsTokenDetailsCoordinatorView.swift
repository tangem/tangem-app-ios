//
//  MarketsTokenDetailsCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct MarketsTokenDetailsCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: MarketsTokenDetailsCoordinator

    var body: some View {
        ZStack {
            if let viewModel = coordinator.rootViewModel {
                MarketsTokenDetailsView(viewModel: viewModel)
                    .navigationLinks(links)
            }

            sheets
        }
        .bindAlert($coordinator.error)
    }

    @ViewBuilder
    var sheets: some View {
        NavHolder()
            .sheet(item: $coordinator.expressCoordinator) { coordinator in
                ExpressCoordinatorView(coordinator: coordinator)
            }
            .sheet(item: $coordinator.stakingDetailsCoordinator) { coordinator in
                StakingDetailsCoordinatorView(coordinator: coordinator)
                    .stakingNavigationView()
            }
            .sheet(item: $coordinator.yieldModuleActiveCoordinator) {
                YieldModuleActiveCoordinatorView(coordinator: $0)
            }
            .sheet(item: $coordinator.sendCoordinator) {
                SendCoordinatorView(coordinator: $0)
            }
            .detentBottomSheet(
                item: $coordinator.tokenNetworkSelectorCoordinator,
                detents: [.large],
            ) {
                MarketsTokenNetworkSelectorCoordinatorView(coordinator: $0)
            }
            .floatingSheetContent(for: ReceiveMainViewModel.self) {
                ReceiveMainView(viewModel: $0)
            }
    }

    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.exchangesListViewModel) { viewModel in
                NavigationBarHidingView(shouldWrapInNavigationStack: false) {
                    MarketsTokenDetailsExchangesListView(viewModel: viewModel)
                }
            }
            .navigation(item: $coordinator.newsPagerViewModel) { viewModel in
                NewsPagerView(viewModel: viewModel)
                    .navigationLinks(newsRelatedTokenDetailsLink)
            }
            .fullScreenCover(item: $coordinator.yieldModulePromoCoordinator) { coordinator in
                NavigationView {
                    YieldModulePromoCoordinatorView(coordinator: coordinator)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                backButton
                            }
                        }
                }
            }
            .fullScreenCover(item: $coordinator.tokenDetailsCoordinator, content: { item in
                NavigationView {
                    TokenDetailsCoordinatorView(coordinator: item)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                backButton
                            }
                        }
                }
            })
    }

    private var backButton: some View {
        BackButton(
            height: Constants.backButtonHeight,
            isVisible: true,
            isEnabled: true,
            hPadding: Constants.backButtonHorizontalPadding,
            action: { UIApplication.dismissTop() }
        )
    }

    private var newsRelatedTokenDetailsLink: some View {
        NavHolder()
            .navigation(item: $coordinator.newsRelatedTokenDetailsCoordinator) { tokenCoordinator in
                MarketsTokenDetailsCoordinatorView(coordinator: tokenCoordinator)
                    .ignoresSafeArea(.container, edges: .top)
            }
    }
}

// MARK: - Constants

private extension MarketsTokenDetailsCoordinatorView {
    enum Constants {
        static let backButtonHorizontalPadding: CGFloat = -6
        static let backButtonHeight: CGFloat = 44.0
    }
}
