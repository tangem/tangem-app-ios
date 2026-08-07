//
//  PriceAlertsScreenCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct PriceAlertsScreenCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: PriceAlertsScreenCoordinator

    var body: some View {
        if let rootViewModel = coordinator.rootViewModel {
            PriceAlertsScreenView(viewModel: rootViewModel)
        }
    }
}
