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
            ZStack {
                if let rootViewModel = coordinator.rootViewModel {
                    SendReceiveTokensListView(viewModel: rootViewModel)
                }

                sheets
            }
        }
    }

    @ViewBuilder
    private var sheets: some View {
        NavHolder()
            .floatingSheetContent(for: SendReceiveTokenNetworkSelectorViewModel.self) {
                SendReceiveTokenNetworkSelectorView(viewModel: $0)
            }
    }
}
