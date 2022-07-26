//
//  AppSettingsCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct AppSettingsCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: AppSettingsCoordinator

    init(coordinator: AppSettingsCoordinator) {
        self.coordinator = coordinator
    }

    var body: some View {
        if let rootViewModel = coordinator.rootViewModel {
            AppSettingsView(viewModel: rootViewModel)
        }
    }
}
