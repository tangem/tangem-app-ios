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

    var body: some View {
        let isMainScreenBottomSheetEnabled = FeatureProvider.isAvailable(.mainScreenBottomSheet)
        let hasManageTokensViewModel = coordinator.manageTokensViewModel != nil

        NavigationView {
            if let welcomeCoordinator = coordinator.welcomeCoordinator {
                WelcomeCoordinatorView(coordinator: welcomeCoordinator)
            } else if let uncompletedBackupCoordinator = coordinator.uncompletedBackupCoordinator {
                UncompletedBackupCoordinatorView(coordinator: uncompletedBackupCoordinator)
            } else if let authCoordinator = coordinator.authCoordinator {
                AuthCoordinatorView(coordinator: authCoordinator)
                    .if(isMainScreenBottomSheetEnabled) { view in
                        view.animation(nil) // Fixes weird animations on appear when the view has a bottom scrollable sheet
                    }
            }
        }
        .navigationViewStyle(.stack)
        .accentColor(Colors.Text.primary1)
        .if(isMainScreenBottomSheetEnabled) { view in
            // Unfortunately, we can't just apply the `bottomScrollableSheet` modifier here conditionally only when
            // `coordinator.manageTokensViewModel != nil` because this will break the root view's structural identity and
            // therefore all its state. So dummy views (`Color.clear`) are used as `header`/`content` views placeholders.
            view.bottomScrollableSheet(
                prefersGrabberVisible: hasManageTokensViewModel,
                allowsHitTesting: hasManageTokensViewModel,
                header: {
                    if let viewModel = coordinator.manageTokensViewModel {
                        ManageTokensBottomSheetHeaderContainerView(viewModel: viewModel)
                    } else {
                        Color.clear.frame(size: .zero)
                    }
                },
                content: {
                    if let viewModel = coordinator.manageTokensViewModel {
                        ManageTokensBottomSheetContentView(viewModel: viewModel)
                    } else {
                        Color.clear.frame(size: .zero)
                    }
                }
            )
        }
    }
}
