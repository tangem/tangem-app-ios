//
//  MarketsCoordinatorView.swift
//  Tangem
//
//  Created by skibinalexander on 15.09.2023.
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
                    MarketsView(viewModel: model)
                        .navigationLinks(links)

                    sheets
                }
            }
            .navigationViewStyle(.stack)
            .tint(Colors.Text.primary1)
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
            .emptyNavigationLink()
    }
}
