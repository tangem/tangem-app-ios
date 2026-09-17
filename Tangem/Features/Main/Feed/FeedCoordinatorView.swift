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
    @Namespace private var zoomNamespace

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
                .environment(\.feedZoomNamespace, zoomNamespace)
                .fullScreenCover(item: $coordinator.cover) { FeedCoverView(cover: $0, namespace: zoomNamespace) }
            }

            NavHolder()
                .sheet(item: presentation(fullScreen: false), onDismiss: coordinator.accountFormDidDismiss) {
                    FeedDestinationView(destination: $0)
                }
                .fullScreenCover(item: presentation(fullScreen: true)) {
                    FeedDestinationView(destination: $0)
                }
                .floatingSheetContent(for: AddAccountTypeSelectorViewModel.self) {
                    AddAccountTypeSelectorView(viewModel: $0)
                }
        }
    }

    private func presentation(fullScreen: Bool) -> Binding<FeedDestination?> {
        Binding(
            get: {
                guard let destination = coordinator.presented,
                      destination.isFullScreenPresentation == fullScreen else { return nil }
                return destination
            },
            set: { destination in
                guard destination == nil, let current = coordinator.presented,
                      current.isFullScreenPresentation == fullScreen else { return }

                coordinator.dismissPresented()
            }
        )
    }
}
