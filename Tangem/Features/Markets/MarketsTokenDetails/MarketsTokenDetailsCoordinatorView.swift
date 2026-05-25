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
        switch coordinator.presentationStyle {
        case .marketsSheet, .navigationStack:
            content

        case .fullScreenCover:
            NavigationStack {
                content
                    .toolbar {
                        NavigationToolbarButton.close(placement: .topBarLeading, action: coordinator.dismiss)
                            .redesigned()

                        NavigationToolbarButton.share(
                            placement: .topBarTrailing,
                            action: { coordinator.rootViewModel?.shareTokenDetails() }
                        )
                        .redesigned()
                    }
            }
        }
    }

    private var content: some View {
        ZStack {
            if let viewModel = coordinator.rootViewModel {
                MarketsTokenDetailsView(viewModel: viewModel)
                    .navigationLinks(links)
            }

            sheets
        }
        .bindAlert($coordinator.error)
    }

    var sheets: some View {
        NavHolder()
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
                NavigationStack {
                    YieldModulePromoCoordinatorView(coordinator: coordinator)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                backButton {
                                    self.coordinator.yieldModulePromoCoordinator = nil
                                }
                            }
                        }
                }
            }
            .fullScreenCover(item: $coordinator.tokenDetailsCoordinator) { item in
                NavigationStack {
                    TokenDetailsCoordinatorView(coordinator: item)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                backButton {
                                    coordinator.tokenDetailsCoordinator = nil
                                }
                            }
                        }
                }
            }
    }

    private func backButton(action: @escaping () -> Void) -> some View {
        BackButton(
            height: 44.0,
            isVisible: true,
            isEnabled: true,
            hPadding: -6,
            action: action
        )
    }

    private var newsRelatedTokenDetailsLink: some View {
        NavHolder()
            .navigation(item: $coordinator.newsRelatedTokenDetailsCoordinator) { tokenCoordinator in
                MarketsTokenDetailsCoordinatorView(coordinator: tokenCoordinator)
                    .if(tokenCoordinator.isMarketsSheetFlow) { view in
                        view.ignoresSafeArea(.container, edges: .top)
                    }
            }
    }
}
