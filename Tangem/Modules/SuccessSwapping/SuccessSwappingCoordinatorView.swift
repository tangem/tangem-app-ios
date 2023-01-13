//
//  SuccessSwappingCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct SuccessSwappingCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: SuccessSwappingCoordinator

    init(coordinator: SuccessSwappingCoordinator) {
        self.coordinator = coordinator
    }

    var body: some View {
        ZStack {
            if let rootViewModel = coordinator.rootViewModel {
                SuccessSwappingView(viewModel: rootViewModel)
            }

            sheets
        }
    }

    @ViewBuilder
    private var sheets: some View {
        NavHolder()
            .sheet(item: $coordinator.webViewContainerViewModel) {
                WebViewContainer(viewModel: $0)
            }
    }
}
