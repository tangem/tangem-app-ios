//
//  TokenMarketsDetailsCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct TokenMarketsDetailsCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: TokenMarketsDetailsCoordinator

    var body: some View {
        ZStack {
            if let viewModel = coordinator.rootViewModel {
                TokenMarketsDetailsView(viewModel: viewModel)
            }

            sheets
        }
    }

    var sheets: some View {
        NavHolder()
    }
}
