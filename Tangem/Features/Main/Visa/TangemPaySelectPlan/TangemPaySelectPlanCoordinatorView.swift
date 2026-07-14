//
//  TangemPaySelectPlanCoordinatorView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct TangemPaySelectPlanCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: TangemPaySelectPlanCoordinator

    var body: some View {
        if let viewModel = coordinator.selectPlanViewModel {
            TangemPaySelectPlanView(viewModel: viewModel)
                .navigationLinks(links)
        }
    }

    private var links: some View {
        NavHolder()
            .floatingSheetContent(for: TangemPayComparePlansSheetViewModel.self) {
                TangemPayComparePlansSheetView(viewModel: $0)
            }
    }
}
