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
            .iOS16UIKitSheet(item: $coordinator.expressCoordinator) { coordinator in
                ExpressCoordinatorView(coordinator: coordinator)
            }
            .iOS16UIKitSheet(item: $coordinator.stakingDetailsCoordinator) { coordinator in
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

        NavHolder()
            .bottomSheet(
                item: $coordinator.receiveBottomSheetViewModel,
                settings: .init(backgroundColor: Colors.Background.primary, contentScrollsHorizontally: true)
            ) {
                ReceiveBottomSheetView(viewModel: $0)
            }
    }

    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.exchangesListViewModel) { viewModel in
                NavigationBarHidingView(shouldWrapInNavigationStack: false) {
                    MarketsTokenDetailsExchangesListView(viewModel: viewModel)
                }
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
            hPadding: -6,
            action: { UIApplication.dismissTop() }
        )
    }
}

// MARK: - Constants

private extension MarketsTokenDetailsCoordinatorView {
    enum Constants {
        static let backButtonHeight: CGFloat = 44.0
        static let backButtonHorizontalPadding: CGFloat = 10.0
    }
}
