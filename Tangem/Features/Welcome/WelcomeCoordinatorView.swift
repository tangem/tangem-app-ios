//
//  WelcomeCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct WelcomeCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: WelcomeCoordinator

    @Environment(\.colorScheme) private var systemColorScheme

    var body: some View {
        NavigationStack {
            content
                .navigationLinks(links)
        }
        .overlay(overlays)
        .overlay(sheets)
        .environment(\.colorScheme, .dark)
    }

    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.importOnboardingCoordinator) {
                OnboardingCoordinatorView(coordinator: $0)
                    .navigationBarHidden(true)
            }
            .navigation(item: $coordinator.createWalletSelectorCoordinator) {
                CreateWalletSelectorCoordinatorView(coordinator: $0)
                    .environment(\.colorScheme, systemColorScheme)
            }
    }

    private var content: some View {
        ZStack {
            if let rootViewModel = coordinator.rootViewModel {
                WelcomeView(viewModel: rootViewModel)
            }

            sheetsContent
        }
        .confirmationDialog(viewModel: $coordinator.scanTroubleshootingDialog)
        .fullScreenCover(item: $coordinator.legalViewModel) { legalViewModel in
            WebViewContainer(viewModel: legalViewModel.webViewModel)
                .background(legalViewModel.backgroundStyle)
                .environment(\.colorScheme, legalViewModel.colorScheme)
        }
    }

    private var overlays: some View {
        ZStack {
            if let storyViewModel = coordinator.welcomeStoryViewModel {
                WelcomeStoryView(viewModel: storyViewModel)
                    .transition(.opacity)
            }

            ZStack {
                if let tangemPayMobileOnboardingCoordinator = coordinator.tangemPayMobileOnboardingCoordinator {
                    TangemPayMobileOnboardingCoordinatorView(coordinator: tangemPayMobileOnboardingCoordinator)
                        .environment(\.colorScheme, systemColorScheme)
                        .transition(.opacity)
                }
            }

            ZStack {
                if let tangemPayCampaignCoordinator = coordinator.tangemPayCampaignCoordinator {
                    TangemPayCampaignCoordinatorView(coordinator: tangemPayCampaignCoordinator)
                        .environment(\.colorScheme, systemColorScheme)
                        .transition(.opacity)
                }
            }
        }
        .animation(.easeInOut(duration: 0.35), value: coordinator.welcomeStoryViewModel != nil)
        .animation(.easeInOut(duration: 0.35), value: coordinator.tangemPayMobileOnboardingCoordinator != nil)
        .animation(.easeInOut(duration: 0.35), value: coordinator.tangemPayCampaignCoordinator != nil)
    }

    /// Sheets are presented locally instead of via the global `FloatingSheetPresenter`:
    /// this flow runs before the app reaches its main state, where `AppCoordinator` keeps
    /// the global presenter paused, so an enqueued sheet would only pop up later on the main screen.
    private var sheets: some View {
        EmptyView()
            .floatingSheet(
                viewModel: coordinator.actionSheetViewModel,
                dismissSheetAction: { [weak coordinator] in
                    coordinator?.handleBackgroundSheetDismiss()
                }
            )
            .allowsHitTesting(coordinator.actionSheetViewModel != nil)
    }

    private var sheetsContent: some View {
        NavHolder()
            .floatingSheetContent(for: WelcomeActionSheetViewModel.self) {
                WelcomeActionSheetView(viewModel: $0)
            }
    }
}
