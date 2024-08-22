//
//  MarketsCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct MarketsCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: MarketsCoordinator

    var body: some View {
        if let model = coordinator.rootViewModel {
            NavigationView {
                ZStack {
                    VStack(spacing: 0.0) {
                        header
                            .zIndex(100) // Required for the collapsible header in `MarketsView` to work

                        MarketsView(viewModel: model)
                            .navigationLinks(links)
                    }

                    sheets
                }
                .onOverlayContentStateChange { [weak coordinator] state in
                    // This method maintains a strong reference to the given `observer` closure,
                    // so a weak capture list is required
                    coordinator?.onOverlayContentStateChange(state)
                }
            }
            .navigationViewStyle(.stack)
            .tint(Colors.Text.primary1)
        }
    }

    @ViewBuilder
    private var header: some View {
        if let headerViewModel = coordinator.headerViewModel {
            MainBottomSheetHeaderView(viewModel: headerViewModel)
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private var sheets: some View {
        NavHolder()
            .bottomSheet(
                item: $coordinator.marketsListOrderBottomSheetViewModel,
                backgroundColor: Colors.Background.tertiary
            ) {
                MarketsListOrderBottomSheetView(viewModel: $0)
            }
    }

    @ViewBuilder
    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.tokenMarketsDetailsCoordinator) {
                TokenMarketsDetailsCoordinatorView(coordinator: $0)
            }
    }
}
