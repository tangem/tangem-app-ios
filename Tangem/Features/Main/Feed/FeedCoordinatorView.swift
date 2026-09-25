//
//  FeedCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils

struct FeedCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: FeedCoordinator

    @Environment(\.mainShtorkaSize) private var sheetSize
    @Namespace private var zoomNamespace

    var body: some View {
        ZStack {
            if let viewModel = coordinator.rootViewModel, let container = coordinator.container {
                NavigationStack(path: $coordinator.path) {
                    FeedView(
                        viewModel: viewModel,
                        searchViewModel: viewModel.searchViewModel,
                        container: container,
                        isContentVisible: coordinator.path.isEmpty && coordinator.presented == nil && coordinator.cover == nil
                    )
                    .background(FeedPopGestureEnabler())
                    .navigationDestination(for: FeedDestination.self) {
                        FeedDestinationView(destination: $0)
                            .scrollDisabled(sheetSize.isNonFullFeedSheet)
                    }
                }
                .simultaneousGesture(TapGesture().onEnded {
                    if sheetSize.isCollapsedFeedSheet {
                        container.expand()
                    }
                })
                .onAnimationCompleted(for: sheetSize == .full, completion: coordinator.sheetDidFinishExpanding)
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
                .floatingSheetContent(for: FeedReferralWalletSelectorViewModel.self) {
                    FeedReferralWalletSelectorView(viewModel: $0)
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
