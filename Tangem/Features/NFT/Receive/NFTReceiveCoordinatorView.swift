//
//  NFTReceiveCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemNFT
import TangemAssets
import TangemUI

struct NFTReceiveCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: NFTReceiveCoordinator

    var body: some View {
        ZStack {
            if let rootViewModel = coordinator.rootViewModel {
                NavigationStack {
                    NFTNetworkSelectionListView(viewModel: rootViewModel)
                        .navigationBarTitleDisplayMode(.inline)
                }
            }

            sheets
        }
    }

    @ViewBuilder
    var sheets: some View {
        NavHolder()
            .bottomSheet(
                item: $coordinator.receiveBottomSheetViewModel,
                settings: .init(backgroundColor: Colors.Background.primary, contentScrollsHorizontally: true)
            ) {
                ReceiveBottomSheetView(viewModel: $0)
            }
            .floatingSheetContent(for: ReceiveMainViewModel.self) {
                ReceiveMainView(viewModel: $0)
            }
    }
}
