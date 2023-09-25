//
//  ManageTokensNetworkSelectorCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

struct ManageTokensNetworkSelectorCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: ManageTokensNetworkSelectorCoordinator

    var body: some View {
        ZStack {
            NavigationView {
                if let model = coordinator.manageTokensNetworkSelectorViewModel {
                    ManageTokensNetworkSelectorView(viewModel: model)
                        .navigationLinks(links)
                }
            }
            .navigationViewStyle(.stack)
        }
    }

    @ViewBuilder
    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.walletSelectorViewModel) {
                WalletSelectorView(viewModel: $0)
            }
            .emptyNavigationLink()
    }
}
