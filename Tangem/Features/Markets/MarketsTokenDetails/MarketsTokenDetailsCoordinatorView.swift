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
            .sheet(item: $coordinator.mailViewModel) {
                MailView(viewModel: $0)
            }
            .iOS16UIKitSheet(item: $coordinator.expressCoordinator) { coordinator in
                ExpressCoordinatorView(coordinator: coordinator)
                    .expressNavigationView()
            }
            .iOS16UIKitSheet(item: $coordinator.stakingDetailsCoordinator) { coordinator in
                StakingDetailsCoordinatorView(coordinator: coordinator)
                    .stakingNavigationView()
            }
            .sheet(item: $coordinator.sendCoordinator) {
                SendCoordinatorView(coordinator: $0)
            }
            .detentBottomSheet(
                item: $coordinator.tokenNetworkSelectorCoordinator,
                detents: [.large],
                settings: .init(background: Colors.Background.tertiary)
            ) {
                MarketsTokenNetworkSelectorCoordinatorView(coordinator: $0)
            }

        NavHolder()
            .bottomSheet(
                item: $coordinator.receiveBottomSheetViewModel,
                settings: .init(backgroundColor: Colors.Background.primary, contentScrollsHorizontally: true)
            ) {
                ReceiveBottomSheetView(viewModel: $0)
            }
    }

    @ViewBuilder
    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.exchangesListViewModel) { viewModel in
                let container = NavigationBarHidingView(shouldWrapInNavigationView: false) {
                    MarketsTokenDetailsExchangesListView(viewModel: viewModel)
                }

                if #available(iOS 16, *) {
                    container
                } else {
                    container
                        .ignoresSafeArea(.container, edges: .vertical) // Without this on iOS 15 content won't ignore safe area and don't go below navbar
                }
            }
            .emptyNavigationLink()
    }
}
