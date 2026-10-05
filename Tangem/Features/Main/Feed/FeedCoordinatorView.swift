//
//  FeedCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
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
                .sheet(item: presentation(fullScreen: false), onDismiss: coordinator.presentationDidDismiss) {
                    FeedDestinationView(destination: $0)
                }
                .fullScreenCover(item: presentation(fullScreen: true), onDismiss: coordinator.presentationDidDismiss) {
                    FeedDestinationView(destination: $0)
                }
                .modifier(FeedWalletSelectorModal(presenter: coordinator.widgetSheetPresenter))
                .floatingSheetContent(for: AddAccountTypeSelectorViewModel.self) {
                    AddAccountTypeSelectorView(viewModel: $0)
                }
        }
        .modifier(FeedModalPresentation(coordinator: coordinator))
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

private struct FeedWalletSelectorModal: ViewModifier {
    @ObservedObject var presenter: FeedWidgetSheetPresenter

    func body(content: Content) -> some View {
        content.modal(
            isPresented: $presenter.isWalletSelectorPresented,
            contentLayout: .intrinsic,
            dragIndicator: .hidden,
            title: Localization.commonChooseWallet,
            onDismiss: presenter.walletSelectorDidDismiss
        ) {
            switch presenter.walletSelector {
            case .accounts(let viewModel):
                AccountSelectorView(viewModel: viewModel, style: .modal)
            case .referral(let viewModel):
                FeedReferralWalletSelectorView(viewModel: viewModel)
            case nil:
                EmptyView()
            }
        }
    }
}
