//
//  PolymarketCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct PolymarketCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: PolymarketCoordinator

    var body: some View {
        if let viewModel = coordinator.rootViewModel {
            PolymarketMainView(viewModel: viewModel)
        }
    }
}
