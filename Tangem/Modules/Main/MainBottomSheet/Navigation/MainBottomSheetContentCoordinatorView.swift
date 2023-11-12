//
//  MainBottomSheetContentCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

/// - Note: Multiple separate root coordinator views are used in this module due to the architecture of the
/// scrollable bottom sheet UI component, which consists of three parts (views) - `header`, `content` and `overlay`.
struct MainBottomSheetContentCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: MainBottomSheetCoordinator

    var body: some View {
        if let viewModel = coordinator.contentViewModel {
            ZStack {
                MainBottomSheetContentView(viewModel: viewModel)

                sheets
            }
        }
    }

    @ViewBuilder private var sheets: some View {
        NavHolder()
            .sheet(item: $coordinator.networkSelectorCoordinator) {
                ManageTokensNetworkSelectorCoordinatorView(coordinator: $0)
            }
    }
}
