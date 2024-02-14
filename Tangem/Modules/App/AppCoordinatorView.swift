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

    var body: some View {
        Group {
            if let mainBottomSheetCoordinator = coordinator.mainBottomSheetCoordinator {
                content
                    .bottomScrollableSheet(
                        item: mainBottomSheetCoordinator,
                        header: MainBottomSheetHeaderCoordinatorView.init,
                        content: MainBottomSheetContentCoordinatorView.init,
                        overlay: MainBottomSheetOverlayCoordinatorView.init
                    )
                    .bottomScrollableSheetConfiguration(
                        isHiddenWhenCollapsed: true,
                        allowsHitTesting: coordinator.isMainBottomSheetShown
                    )
                    .onBottomScrollableSheetStateChange(
                        weakify(mainBottomSheetCoordinator, forFunction: MainBottomSheetCoordinator.onBottomScrollableSheetStateChange)
                    )
            } else {
                content
            }
        }
        .bottomSheet(
            item: $sensitiveTextVisibilityViewModel.informationHiddenBalancesViewModel,
            backgroundColor: Colors.Background.primary
        ) {
            InformationHiddenBalancesView(viewModel: $0)
        }
    }

    private var content: some View {
        NavigationView {
            if let welcomeCoordinator = coordinator.welcomeCoordinator {
                WelcomeCoordinatorView(coordinator: welcomeCoordinator)
            } else if let uncompletedBackupCoordinator = coordinator.uncompletedBackupCoordinator {
                UncompletedBackupCoordinatorView(coordinator: uncompletedBackupCoordinator)
            } else if let authCoordinator = coordinator.authCoordinator {
                AuthCoordinatorView(coordinator: authCoordinator)
                    .transaction { transaction in // Fixes weird animations on appear when the view has a bottom scrollable sheet
                        if coordinator.mainBottomSheetCoordinator != nil {
                            transaction.animation = nil
                        }
                    }
            }
        }
        .navigationViewStyle(.stack)
        .accentColor(Colors.Text.primary1)
    }
}
