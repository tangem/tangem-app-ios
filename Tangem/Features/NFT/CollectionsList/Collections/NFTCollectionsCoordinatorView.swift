//
//  NFTEntrypointCoordinatorView.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUIUtils
import TangemNFT
import TangemUI
import TangemLocalization

struct NFTCollectionsCoordinatorView: View {
    @ObservedObject var coordinator: NFTCollectionsCoordinator

    var body: some View {
        ZStack {
            if let rootViewModel = coordinator.rootViewModel {
                NFTCollectionsListView(viewModel: rootViewModel)
            }

            sheets
        }
    }

    private var sheets: some View {
        NavHolder()
            .sheet(item: $coordinator.receiveCoordinator) { coordinator in
                NFTReceiveCoordinatorView(coordinator: coordinator)
                    .presentationCornerRadius(24.0)
            }
            .sheet(item: $coordinator.assetDetailsCoordinator) {
                NFTAssetDetailsCoordinatorView(coordinator: $0)
            }
            // Floating sheets are controlled by the global `FloatingSheetRegistry` singleton instance, therefore
            // weakly capture is required here to avoid retaining the `coordinator` instance forever
            .floatingSheetContent(for: AccountSelectorViewModel.self) { [weak coordinator] viewModel in
                FloatingSheetContentWithHeader(
                    headerConfig: .init(
                        title: viewModel.state.navigationBarTitle,
                        backAction: nil,
                        closeAction: {
                            coordinator?.closeSheet()
                        }
                    ),
                    content: {
                        AccountSelectorView(viewModel: viewModel)
                    }
                )
                .floatingSheetConfiguration { config in
                    config.backgroundInteractionBehavior = .tapToDismiss
                }
            }
    }
}
