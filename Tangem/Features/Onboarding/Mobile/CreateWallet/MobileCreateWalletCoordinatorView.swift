//
//  MobileCreateWalletCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct MobileCreateWalletCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: MobileCreateWalletCoordinator

    var body: some View {
        ZStack {
            if let viewModel = coordinator.rootViewModel {
                MobileCreateWalletView(viewModel: viewModel)
                    .navigationBarHidden(true)
                    .navigationLinks(links)
            }

            sheetsContent
        }
        .overlay(sheets)
    }

    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.onboardingCoordinator) {
                OnboardingCoordinatorView(coordinator: $0)
                    .navigationBarHidden(true)
            }
    }

    /// Sheets are presented locally instead of via the global `FloatingSheetPresenter`:
    /// this flow runs before the app reaches its main state, where `AppCoordinator` keeps
    /// the global presenter paused, so an enqueued sheet would only pop up later on the main screen.
    private var sheets: some View {
        EmptyView()
            .floatingSheet(
                viewModel: coordinator.importWalletViewModel,
                dismissSheetAction: coordinator.closeImportWallet
            )
            .allowsHitTesting(coordinator.importWalletViewModel != nil)
    }

    private var sheetsContent: some View {
        NavHolder()
            .floatingSheetContent(for: MobileImportWalletViewModel.self) {
                MobileImportWalletView(viewModel: $0)
            }
    }
}
