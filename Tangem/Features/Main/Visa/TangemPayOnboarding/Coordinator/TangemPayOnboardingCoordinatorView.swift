//
//  TangemPayOnboardingCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct TangemPayOnboardingCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: TangemPayOnboardingCoordinator

    var body: some View {
        ZStack {
            if let rootViewModel = coordinator.rootViewModel {
                TangemPayOnboardingView(viewModel: rootViewModel)
            }

            sheets
        }
    }

    @ViewBuilder
    private var sheets: some View {
        NavHolder()
            .floatingSheetContent(for: TangemPayWalletSelectorViewModel.self) {
                TangemPayWalletSelectorProxyView(viewModel: $0)
            }
    }

    @ViewBuilder
    private var links: some View {
        EmptyView()
    }
}
