//
//  ScanCardSettingsCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct ScanCardSettingsCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: ScanCardSettingsCoordinator

    init(coordinator: ScanCardSettingsCoordinator) {
        self.coordinator = coordinator
    }

    var body: some View {
        if let rootViewModel = coordinator.scanCardSettingsViewModel {
            ScanCardSettingsView(viewModel: rootViewModel)
                .navigation(item: $coordinator.cardSettingsCoordinator) {
                    CardSettingsCoordinatorView(coordinator: $0)
                }
                .emptyNavigationLink()
        }
    }
}
