//
//  YieldModuleActiveCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct YieldModuleActiveCoordinatorView: View {
    @ObservedObject var coordinator: YieldModuleActiveCoordinator

    init(coordinator: YieldModuleActiveCoordinator) {
        self.coordinator = coordinator
    }

    var body: some View {
        ZStack {
            if let viewModel = coordinator.rootViewModel {
                YieldModuleActiveContentView(viewModel: viewModel)
            }

            sheets
        }
    }

    @ViewBuilder
    private var sheets: some View {
        NavHolder()
            .floatingSheetContent(for: YieldModuleTransactionViewModel.self) {
                YieldModuleTransactionView(viewModel: $0)
            }
    }
}
