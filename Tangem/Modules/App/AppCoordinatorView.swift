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

    var body: some View {
        NavigationView {
            switch coordinator.viewState {
            case .welcome(let welcomeCoordinator):
                WelcomeCoordinatorView(coordinator: welcomeCoordinator)
            case .uncompleteBackup(let uncompletedBackupCoordinator):
                UncompletedBackupCoordinatorView(coordinator: uncompletedBackupCoordinator)
            case .auth(let authCoordinator):
                AuthCoordinatorView(coordinator: authCoordinator)
            case .main(let mainCoordinator):
                MainCoordinatorView(coordinator: mainCoordinator)
            case .none:
                EmptyView()
            }
        }
        .animation(.default, value: coordinator.viewState)
        .navigationViewStyle(.stack)
        .accentColor(Colors.Text.primary1)
        .overlayContentContainer(item: $coordinator.marketsCoordinator) { coordinator in
            let viewHierarchySnapshotter = ViewHierarchySnapshottingContainerViewController()
            let adapter = ViewHierarchySnapshottingWeakifyAdapter(adaptee: viewHierarchySnapshotter)
            let marketsCoordinatorView = MarketsCoordinatorView(coordinator: coordinator)
                .environment(\.mainWindowSize, mainWindowSize)
                .environment(\.viewHierarchySnapshotter, adapter)

            UIAppearanceBoundaryContainerView(
                boundaryMarker: { viewHierarchySnapshotter },
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
}
