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
                EarnDetailView(viewModel: viewModel)
            }

            NavHolder()
                .bottomSheet(
                    item: $coordinator.filterBottomSheetViewModel,
                    backgroundColor: Colors.Background.tertiary
                ) {
                    EarnFilterBottomSheetView(viewModel: $0)
                }
        }
        .bindAlert($coordinator.error)
    }
}
