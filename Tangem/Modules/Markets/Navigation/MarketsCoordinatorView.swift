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
            VStack(spacing: 0.0) {
                // This spacer is required to make the system navigation bar on the 'Details' view
                // look like it does on mockups (higher than the default one, 44pt)
                FixedSpacer.vertical(Constants.topInset)

                NavigationView {
                    ZStack {
                        VStack(spacing: 0.0) {
                            header

                            MarketsView(viewModel: model)
                                .navigationLinks(links)
                        }

                        sheets
                    }
                    .offset(y: -Constants.topInset)
                    .onOverlayContentStateChange { state in
                        coordinator.onOverlayContentStateChange(state)
                    }
                }
                .tint(Colors.Text.primary1)
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

// MARK: - Constants

private extension MarketsCoordinatorView {
    enum Constants {
        /// Based on mockups.
        static let customNavigationBarHeight = 64.0
        static let defaultCompactNavigationBarHeight = 44.0
        static var topInset: CGFloat { max(customNavigationBarHeight - defaultCompactNavigationBarHeight, .zero) }
    }
}
