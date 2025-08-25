//
//  SendReceiveTokenCoordinatorView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct SendReceiveTokenCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: SendReceiveTokenCoordinator

    var body: some View {
        NavigationView {
            if let rootViewModel = coordinator.rootViewModel {
                SendReceiveTokensListView(viewModel: rootViewModel)
                    .navigationLinks(links)
            }
        }
    }

    @ViewBuilder
    private var links: some View {
        NavHolder()
            .floatingSheetContent(for: SendReceiveTokenNetworkSelectorViewModel.self) {
                SendReceiveTokenNetworkSelectorView(viewModel: $0)
            }
            .emptyNavigationLink()
    }
}
