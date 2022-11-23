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
        NavigationView {
            SwappingCoordinatorView(coordinator: SwappingCoordinator(dismissAction: {}, popToRootAction: { _ in }))
        }

//        WelcomeCoordinatorView(coordinator: coordinator.welcomeCoordinator)
    }
}
