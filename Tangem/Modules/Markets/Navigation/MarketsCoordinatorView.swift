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

                        MarketsView(viewModel: model)
                            .navigationLinks(links)
                    }

                    sheets
                }
                .onOverlayContentStateChange { state in
                    coordinator.onOverlayContentStateChange(state)
                }
            }
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
                item: $coordinator.marketsListOrderBottonSheetViewModel,
                backgroundColor: Colors.Background.tertiary
            ) {
                MarketsListOrderBottonSheetView(viewModel: $0)
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
