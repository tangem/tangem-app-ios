//
//  StakingDetailsCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemLocalization
import TangemAccessibilityIdentifiers

struct StakingDetailsCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: StakingDetailsCoordinator

    init(coordinator: StakingDetailsCoordinator) {
        self.coordinator = coordinator
    }

    var body: some View {
        ZStack {
            if let rootViewModel = coordinator.rootViewModel {
                StakingDetailsView(viewModel: rootViewModel)
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
            .sheet(item: $coordinator.sendCoordinator) {
                SendCoordinatorView(coordinator: $0)
            }
            .sheet(item: $coordinator.multipleRewardsCoordinator) {
                MultipleRewardsCoordinatorView(coordinator: $0)
            }
    }
}

extension StakingDetailsCoordinatorView {
    func stakingNavigationView() -> some View {
        NavigationView {
            self
                .navigationBarTitle(Text(Localization.commonStake), displayMode: .inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        CloseButton(dismiss: { coordinator.dismiss() })
                    }
                }
        }
    }
}
