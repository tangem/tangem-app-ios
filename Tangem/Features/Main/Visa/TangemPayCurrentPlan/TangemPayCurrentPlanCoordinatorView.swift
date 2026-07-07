//
//  TangemPayCurrentPlanCoordinatorView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct TangemPayCurrentPlanCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: TangemPayCurrentPlanCoordinator

    var body: some View {
        if let viewModel = coordinator.currentPlanViewModel {
            TangemPayCurrentPlanView(viewModel: viewModel)
                .navigationLinks(links)
        }
    }

    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.selectPlanViewModel) {
                TangemPaySelectPlanView(viewModel: $0)
            }
            .floatingSheetContent(for: TangemPayComparePlansSheetViewModel.self) {
                TangemPayComparePlansSheetView(viewModel: $0)
            }
    }
}
