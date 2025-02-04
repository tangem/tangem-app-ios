//
//  AppCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct AppCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: AppCoordinator
    @ObservedObject var sensitiveTextVisibilityViewModel = SensitiveTextVisibilityViewModel.shared

    @Environment(\.mainWindowSize) var mainWindowSize: CGSize
    @Environment(\.overlayContentContainer) private var overlayContentContainer
    @Namespace private var namespace

    var body: some View {
        content
            .accentColor(Colors.Text.primary1)
            .overlayContentContainer(item: $coordinator.marketsCoordinator) { coordinator in
                let marketsCoordinatorView = MarketsCoordinatorView(coordinator: coordinator)
                    .environment(\.mainWindowSize, mainWindowSize)

                return UIAppearanceBoundaryContainerView(
                    boundaryMarker: { coordinator.viewHierarchySnapshotter },
                    content: { marketsCoordinatorView }
                )
                // Ensures that this is a full-screen container and keyboard avoidance is disabled to mitigate [REDACTED_INFO]
                .ignoresSafeArea(.all, edges: .vertical)
            }
            .bottomSheet(
                item: $sensitiveTextVisibilityViewModel.informationHiddenBalancesViewModel,
                backgroundColor: Colors.Background.primary
            ) {
                InformationHiddenBalancesView(viewModel: $0)
            }
            .onChange(of: coordinator.isOverlayContentContainerShown) { isShown in
                overlayContentContainer.setOverlayHidden(!isShown)
            }
    }

    @ViewBuilder
    private var content: some View {
        // We need stack to force transition animation work
        ZStack {
            switch coordinator.viewState {
            case .welcome(let welcomeCoordinator):
                WelcomeCoordinatorView(coordinator: welcomeCoordinator)
                    .transition(.opacity.animation(.easeIn))
            case .uncompleteBackup(let uncompletedBackupCoordinator):
                UncompletedBackupCoordinatorView(coordinator: uncompletedBackupCoordinator)
                    .transition(.opacity.animation(.easeIn))
            case .auth(let authCoordinator):
                AuthCoordinatorView(coordinator: authCoordinator)
                    .setNamespace(namespace)
                    .transition(.opacity.animation(.easeIn))
            case .main(let mainCoordinator):
                MainCoordinatorView(coordinator: mainCoordinator)
                    .transition(.opacity.animation(.easeIn))
            case .onboarding(let onboardingCoordinator):
                OnboardingCoordinatorView(coordinator: onboardingCoordinator)
                    .transition(.opacity.animation(.easeIn))
            case .lock:
                LockView(usesNamespace: true)
                    .setNamespace(namespace)
                    .transition(.asymmetric(insertion: .identity, removal: .opacity.animation(.easeOut(duration: 0.3))))
            case .none:
                EmptyView()
            }
        }
    }
}
