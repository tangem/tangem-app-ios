//
//  CardSettingsCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct CardSettingsCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: CardSettingsCoordinator

    var body: some View {
        if let model = coordinator.securityPrivacyViewModel {
            CardSettingsView(viewModel: model)
                .navigation(item: $coordinator.securityManagementCoordinator) {
                    SecurityModeCoordinatorView(coordinator: $0)
                }
                .emptyNavigationLink()
        }
    }
}
