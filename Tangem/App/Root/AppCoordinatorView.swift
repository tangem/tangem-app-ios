//
//  AppCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct AppCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: AppCoordinator
    @ObservedObject var sensitiveTextVisibilityViewModel = SensitiveTextVisibilityViewModel.shared

    @Namespace private var namespace

    var body: some View {
        content
            .accentColor(Colors.Text.primary1)
            .bottomSheet(
                item: $sensitiveTextVisibilityViewModel.informationHiddenBalancesViewModel,
                backgroundColor: Colors.Background.primary
            ) {
                InformationHiddenBalancesView(viewModel: $0)
            }
    }

    private var content: some View {
        // We need stack to force transition animation work
        ZStack {
            switch coordinator.viewState {
            case .welcomeV2(let welcomeV2Coordinator):
                WelcomeV2CoordinatorView(coordinator: welcomeV2Coordinator)
                    .transition(.opacity.animation(.easeIn))
            case .uncompleteBackup(let uncompletedBackupCoordinator):
                UncompletedBackupCoordinatorView(coordinator: uncompletedBackupCoordinator)
                    .transition(.opacity.animation(.easeIn))
            case .auth(let authCoordinator):
                AuthCoordinatorView(coordinator: authCoordinator)
                    .setGeometryEffect(.init(id: TangemIconView.namespaceId, namespace: namespace))
                    .transition(.opacity.animation(.easeIn))
            case .main(let mainCoordinator):
                MainCoordinatorView(coordinator: mainCoordinator)
                    .transition(.opacity.animation(.easeIn))
            case .onboarding(let onboardingCoordinator):
                OnboardingCoordinatorView(coordinator: onboardingCoordinator)
                    .transition(.opacity.animation(.easeIn))
            case .lock:
                LockView(usesNamespace: true)
                    .setGeometryEffect(.init(id: TangemIconView.namespaceId, namespace: namespace))
                    .transition(.asymmetric(insertion: .identity, removal: .opacity.animation(.easeOut(duration: 0.3))))
            case .launch:
                LaunchScreenView()
                    .transition(.asymmetric(
                        insertion: .identity,
                        removal: .opacity.animation(.easeInOut(duration: AppConstants.launchScreenDismissalDuration))
                    ))
            case .jailbreakWarning(let viewModel):
                JailbreakWarningView(viewModel: viewModel)
            case .forceUpdate(let viewModel):
                ForceUpdateView(viewModel: viewModel)
                    .transition(.opacity.animation(.easeIn))
            case .none:
                EmptyView()
            }
        }
    }
}
