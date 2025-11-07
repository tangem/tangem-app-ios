//
//  TangemPayCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct TangemPayCoordinatorView: View {
    @ObservedObject var coordinator: TangemPayCoordinator

    init(coordinator: TangemPayCoordinator) {
        self.coordinator = coordinator
    }

    var body: some View {
        ZStack {
            if let viewModel = coordinator.rootViewModel {
                TangemPayMainView(viewModel: viewModel)
            }

            sheets
        }
    }

    @ViewBuilder
    private var sheets: some View {
        NavHolder()
            .fullScreenCover(item: $coordinator.addToApplePayGuideViewModel) { viewModel in
                TangemPayAddToAppPayGuideView(viewModel: viewModel)
                    .edgesIgnoringSafeArea(.vertical)
            }
    }
}
