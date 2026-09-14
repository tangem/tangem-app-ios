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

    var body: some View {
        ZStack {
            if let viewModel = coordinator.rootViewModel {
                NavigationStack(path: $coordinator.path) {
                    FeedView(
                        viewModel: viewModel,
                        searchViewModel: viewModel.searchViewModel,
                        shtorkaStateObject: coordinator.shtorkaStateObject
                    )
                    .background(FeedPopGestureEnabler())
                    .navigationDestination(for: FeedDestination.self) { FeedDestinationView(destination: $0) }
                }
                .overlay {
                    // A collapsed sheet shows only the header of the screen: the first tap brings the sheet up,
                    // and the screen answers taps — Back included — once the user can see what they are tapping.
                    if coordinator.path.isNotEmpty, coordinator.shtorkaStateObject.size == .collapsed {
                        Color.clear
                            .contentShape(.rect)
                            .onTapGesture { coordinator.shtorkaStateObject.expand() }
                    }
                }
            }

            NavHolder()
                .sheet(item: $coordinator.presented) { FeedDestinationView(destination: $0) }
        }
    }
}
