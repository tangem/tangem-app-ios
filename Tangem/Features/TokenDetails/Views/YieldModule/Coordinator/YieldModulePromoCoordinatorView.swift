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
            if let viewModel = coordinator.rootViewModel {
                YieldModulePromoView(viewModel: viewModel)
            }
        }
    }
}
