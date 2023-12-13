//
//  ManageTokensCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct ManageTokensCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: ManageTokensCoordinator

    var body: some View {
        ZStack {
            if let model = coordinator.manageTokensViewModel {
                ManageTokensView(viewModel: model)
                    .onAppear(perform: model.onAppear)

                if #available(iOS 15.0, *) {
                    ios15Sheets
                } else {
                    ios14Sheets
                }
            }
        }
    }

    @available(iOS 15.0, *)
    @ViewBuilder
    private var ios15Sheets: some View {
        NavHolder()
            .detentBottomSheet(
                item: $coordinator.networkSelectorViewModel,
                settings: .init(
                    detents: [.large],
                    backgroundColor: Colors.Background.primary
                )
            ) { viewModel in
                NavigationView {
                    ManageTokensNetworkSelectorView(viewModel: viewModel)
                        .navigationLinks(links)
                }
                .navigationViewStyle(.stack)
            }
    }

    @ViewBuilder
    private var ios14Sheets: some View {
        NavHolder()
            .sheet(item: $coordinator.networkSelectorViewModel) { viewModel in
                NavigationView {
                    ZStack {
                        ManageTokensNetworkSelectorView(viewModel: viewModel)

                        links
                    }
                }
                .navigationViewStyle(.stack)
            }
        // [REDACTED_TODO_COMMENT]
    }

    @ViewBuilder
    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.walletSelectorViewModel) {
                WalletSelectorView(viewModel: $0)
            }
    }
}
