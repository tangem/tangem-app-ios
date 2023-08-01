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
        BottomSearchableScrollView_Preview.ContentView(data: [String](
            repeating: Date().timeIntervalSince1970.description,
            count: 55
        ))
//
//        NavigationView {
//            if let welcomeCoordinator = coordinator.welcomeCoordinator {
//                WelcomeCoordinatorView(coordinator: welcomeCoordinator)
//            } else if let uncompletedBackupCoordinator = coordinator.uncompletedBackupCoordinator {
//                UncompletedBackupCoordinatorView(coordinator: uncompletedBackupCoordinator)
//            } else if let authCoordinator = coordinator.authCoordinator {
//                AuthCoordinatorView(coordinator: authCoordinator)
//            }
//        }
//        .navigationViewStyle(.stack)
//        .accentColor(Colors.Text.primary1)
    }
}
