//
//  FeedCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct FeedCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: FeedCoordinator

    @Environment(\.mainShtorkaSize) private var sheetSize

    var body: some View {
        ZStack {
            if let viewModel = coordinator.rootViewModel {
                NavigationStack(path: $coordinator.path) {
                    FeedView(
                        viewModel: viewModel,
                        searchViewModel: viewModel.searchViewModel,
                        shtorkaReporting: coordinator.shtorkaReporting,
                        shtorkaActions: coordinator.shtorkaActions
                    )
                    .background(FeedPopGestureEnabler())
                    .navigationDestination(for: FeedDestination.self) { FeedDestinationView(destination: $0) }
                }
                .simultaneousGesture(TapGesture().onEnded {
                    if sheetSize.isCollapsedFeedSheet {
                        coordinator.shtorkaActions.expand()
                    }
                })
            }

            NavHolder()
                .sheet(item: $coordinator.presented) { FeedDestinationView(destination: $0) }
        }
    }
}
