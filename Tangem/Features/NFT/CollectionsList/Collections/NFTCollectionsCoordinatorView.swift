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

    @ViewBuilder
    private var sheets: some View {
        NavHolder()
            .sheet(item: $coordinator.receiveCoordinator) { coordinator in
                NFTReceiveCoordinatorView(coordinator: coordinator)
                    .presentationCornerRadiusBackport(24.0)
            }
            .sheet(item: $coordinator.assetDetailsCoordinator) {
                NFTAssetDetailsCoordinatorView(coordinator: $0)
            }
            .floatingSheetContent(for: AccountSelectorViewModel.self) { viewModel in

                // [REDACTED_TODO_COMMENT]

                VStack(spacing: 0) {
                    BottomSheetHeaderView(
                        title: Localization.commonChooseAccount,
                        trailing: {
                            CircleButton.close(action: coordinator.closeSheet)
                        }
                    )
                    .padding(.horizontal, 16)

                    AccountSelectorView(viewModel: viewModel)
                }
                .floatingSheetConfiguration { config in
                    config.backgroundInteractionBehavior = .tapToDismiss
                }
            }
    }
}
