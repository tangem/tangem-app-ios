//
//  WelcomeV2CoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct WelcomeV2CoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: WelcomeV2Coordinator

    var body: some View {
        NavigationStack {
            content
                .navigationLinks(links)
        }
    }

    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.mobileCreateWalletCoordinator) {
                MobileCreateWalletCoordinatorView(coordinator: $0)
                    .navigationBarHidden(true)
            }
    }

    private var content: some View {
        ZStack {
            if let rootViewModel = coordinator.rootViewModel {
                WelcomeV2View(viewModel: rootViewModel)
            }

            sheetsContent

            if let hardwareViewModel = coordinator.hardwareWalletViewModel {
                WelcomeHardwareWalletView(viewModel: hardwareViewModel)
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: coordinator.hardwareWalletViewModel != nil)
        .overlay(sheets)
    }

    /// Sheets are presented locally instead of via the global `FloatingSheetPresenter`:
    /// this flow runs before the app reaches its main state, where `AppCoordinator` keeps
    /// the global presenter paused, so an enqueued sheet would only pop up later on the main screen.
    private var sheets: some View {
        EmptyView()
            .floatingSheet(
                viewModel: coordinator.actionSheetViewModel,
                dismissSheetAction: { [weak coordinator] in
                    coordinator?.actionSheetViewModel = nil
                }
            )
            .allowsHitTesting(coordinator.actionSheetViewModel != nil)
    }

    private var sheetsContent: some View {
        NavHolder()
            .floatingSheetContent(for: WelcomeV2ActionSheetViewModel.self) {
                WelcomeV2ActionSheetView(viewModel: $0)
            }
    }
}
