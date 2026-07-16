//
//  EarnDetailCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils
import TangemAssets

struct EarnDetailCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: EarnCoordinator

    var body: some View {
        ZStack {
            if let viewModel = coordinator.rootViewModel {
                EarnDetailViewRedesign(viewModel: viewModel)
            }
        }
        .bindAlert($coordinator.error)
    }
}
