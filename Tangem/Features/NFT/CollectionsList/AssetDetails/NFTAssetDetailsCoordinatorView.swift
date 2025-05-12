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
import TangemAssets

struct NFTAssetDetailsCoordinatorView: View {
    @ObservedObject var coordinator: NFTAssetDetailsCoordinator

    var body: some View {
        ZStack {
            if let rootViewModel = coordinator.rootViewModel {
                NavigationView {
                    NFTAssetDetailsView(viewModel: rootViewModel)
                        .withCloseButton(action: coordinator.dismiss)
                        .navigationLinks(links)
                }
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
            .sheet(item: $coordinator.traitsViewData) { viewData in
                NavigationView {
                    NFTAssetExtendedTraitsView(viewData: viewData)
                        .withCloseButton(action: coordinator.closeTraits)
                }
            }

        NavHolder()
            .bottomSheet(
                item: $coordinator.extendedInfoViewData,
                settings: .init(backgroundColor: Colors.Background.action)
            ) {
                NFTAssetExtendedInfoView(
                    viewData: $0,
                    dismissAction: coordinator.closeInfo
                )
            }
    }
}
