//
//  YieldModulePromoCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct YieldModulePromoCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: YieldModulePromoCoordinator

    init(coordinator: YieldModulePromoCoordinator) {
        self.coordinator = coordinator
    }

    var body: some View {
        ZStack {
            if let viewModel = coordinator.rootViewModel {
                YieldModulePromoView(viewModel: viewModel)
            }

            sheets
        }
    }

    @ViewBuilder
    private var sheets: some View {
        NavHolder()
            .floatingSheetContent(for: YieldModuleStartViewModel.self) {
                YieldModuleStartView(viewModel: $0)
            }
    }
}
