//
//  YieldModulePromoCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

struct YieldModulePromoCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: YieldModulePromoCoordinator

    var body: some View {
        ZStack {
            switch coordinator.root {
            case .legacy(let viewModel):
                YieldModulePromoView(viewModel: viewModel)
            case .v2(let viewModel):
                YieldModulePromoV2View(viewModel: viewModel)
            case .none:
                EmptyView()
            }
        }
    }
}
