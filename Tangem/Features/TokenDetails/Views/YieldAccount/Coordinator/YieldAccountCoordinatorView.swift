//
//  YieldAccountCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct YieldAccountPromoCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: YieldAccountPromoCoordinator

    init(coordinator: YieldAccountPromoCoordinator) {
        self.coordinator = coordinator
    }

    var body: some View {
        ZStack {
            if let viewModel = coordinator.rootViewModel {
                YieldAccountPromoView(viewModel: viewModel)
            }

            sheets
        }
    }

    @ViewBuilder
    private var sheets: some View {
        NavHolder()
            .floatingSheetContent(for: YieldInterestRateSheetViewModel.self) {
                YieldInterestRateSheetView(viewModel: $0)
            }
//            .floatingSheetContent(for: YieldInterestRateSheetViewModel.self) {
//                YieldInterestRateSheet(viewModel: $0)
//            }
    }
}
