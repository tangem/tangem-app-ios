//
//  NFTAssetDetailsCoordinatorView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemNFT
import TangemUI

struct NFTAssetDetailsCoordinatorView: View {
    @ObservedObject var coordinator: NFTAssetDetailsCoordinator

    var body: some View {
        ZStack {
            if let rootViewModel = coordinator.rootViewModel {
                NavigationView {
                    makeRootView(with: rootViewModel)
                        .navigationLinks(links)
                }
            }

            sheets
        }
    }

    private func makeRootView(with rootViewModel: NFTAssetDetailsViewModel) -> some View {
        NFTAssetDetailsView(viewModel: rootViewModel)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CloseButton(dismiss: coordinator.dismiss)
                }
            }
    }

    @ViewBuilder
    private var links: some View {
        EmptyView()
    }

    @ViewBuilder
    private var sheets: some View {
        EmptyView()
    }
}
