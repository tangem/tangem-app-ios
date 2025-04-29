//
//  NFTEntrypointCoordinatorView.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemNFT
import TangemUI

struct NFTCollectionsCoordinatorView: View {
    @ObservedObject var coordinator: NFTCollectionsCoordinator

    var body: some View {
        ZStack {
            if let rootViewModel = coordinator.rootViewModel {
                NFTCollectionsListView(viewModel: rootViewModel)
                    .navigationLinks(links)
            }

            sheets
        }
    }

    @ViewBuilder
    private var links: some View {
        EmptyView()
    }

    @ViewBuilder
    private var sheets: some View {
        NavHolder()
            .sheet(item: $coordinator.assetDetailsCoordinator) {
                NFTAssetDetailsCoordinatorView(coordinator: $0)
            }
    }
}
