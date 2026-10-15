//
//  PolymarketActivityCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct PolymarketActivityCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: PolymarketActivityCoordinator

    var body: some View {
        content
            .scrollIndicators(.hidden)
    }

    @ViewBuilder
    private var content: some View {
        if let viewModel = coordinator.rootViewModel {
            PolymarketActivityView(viewModel: viewModel)
        }
    }
}
