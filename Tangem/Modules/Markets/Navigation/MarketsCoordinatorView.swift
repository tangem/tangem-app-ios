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

    @State private var headerHeight: CGFloat = .zero

    private var headerBackdropViewHeight: CGFloat { max(headerHeight - Constants.topInset, 0.0) }

    var body: some View {
        if let model = coordinator.rootViewModel {
            VStack(spacing: 0.0) {
                // This spacer is required to make the system navigation bar on the 'Details' view
                // look like it does on mockups (higher than the default one, 44pt)
                FixedSpacer.vertical(Constants.topInset)

                NavigationView {
                    ZStack {
                        VStack(spacing: 0.0) {
                            // This spacer is used as a backing view for the header view applied as an overlay
                            // (with a height bigger than the height of this spacer)
                            FixedSpacer.vertical(headerBackdropViewHeight)
                                .infinityFrame(axis: .horizontal)
                                .overlay(alignment: .bottom) {
                                    header
                                }

                            MarketsView(viewModel: model)
                                .navigationLinks(links)
                        }

                        sheets
                    }
                    .navigationBarHidden(true)
                    .onOverlayContentStateChange { [weak coordinator] state in
                        coordinator?.onOverlayContentStateChange(state)
                    }
                    .debugBorder(color: .green)
                }
                .tint(Colors.Text.primary1)
            }
        }
    }

    @ViewBuilder
    private var header: some View {
        Group {
            if let headerViewModel = coordinator.headerViewModel {
                MainBottomSheetHeaderView(viewModel: headerViewModel)
            } else {
                EmptyView()
            }
        }
        .readGeometry(\.size.height, bindTo: $headerHeight)
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
