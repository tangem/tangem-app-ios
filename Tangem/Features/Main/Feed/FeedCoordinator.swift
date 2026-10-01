//
//  FeedCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemFoundation
import TangemUIUtils

final class FeedCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    @Published private(set) var rootViewModel: FeedViewModel?
    @Published var path: [FeedDestination] = [] {
        didSet {
            container?.setNavigationActive(path.isNotEmpty)
        }
    }

    @Published var presented: FeedDestination?
    @Published var cover: FeedCover?
    @Published private(set) var modal: FeedModal?

    private(set) var container: (any FeedContainer)?

    private let widgetSheetPresenter = FeedWidgetSheetPresenter()
    private var pendingDestination: FeedDestination?
    private var presentationDismissAction: (() -> Void)?
    private var pendingPresentationDismissActions: [() -> Void] = []
    private var bag = Set<AnyCancellable>()

    required init(dismissAction: @escaping Action<Void>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        container = options.container

        let context = FeedContext(navigation: self, popToRootAction: popToRootAction)
        rootViewModel = FeedViewModelFactory().makeViewModel(
            context: context,
            container: options.container,
            host: options.host,
            selection: options.selection,
            widgetSheetPresenter: widgetSheetPresenter
        )

        bind(to: options.container)
    }

    func apply(selection: FeedSelection) {
        dropRoutes()
        rootViewModel?.searchViewModel.reset()
        rootViewModel?.apply(selection: selection)
    }

    func sheetDidFinishExpanding() {
        guard let pendingDestination else { return }
        self.pendingDestination = nil

        guard let container, container.isPresented, container.size == .full,
              path.isEmpty, presented == nil, cover == nil, !widgetSheetPresenter.isPresenting else { return }

        push(pendingDestination)
    }

    func presentationDidDismiss() {
        let completions = pendingPresentationDismissActions
        pendingPresentationDismissActions.removeAll()
        completions.forEach { $0() }
    }
}

// MARK: - Options

extension FeedCoordinator {
    struct Options {
        let container: any FeedContainer
        /// The screen the feed is shown on, for the destinations it cannot open itself. Absent where the feed
        /// stands on its own: a widget that exists only for that hand-off is left out rather than left dead.
        /// Add account stays either way — creating the account is its own errand, and only the step on to
        /// Manage tokens afterwards has nowhere to go.
        var host: FeedHostRoutable?
        var selection: FeedSelection?
    }
}

// MARK: - FeedNavigation

extension FeedCoordinator: FeedNavigation {
    var isAtRoot: Bool { path.isEmpty && pendingDestination == nil }
    var isFeedPresented: Bool { container?.isPresented == true }

    func push(_ destination: FeedDestination) {
        pendingDestination = nil
        endEditing()
        path.append(destination)
    }

    func pushAfterSheetExpansion(_ destination: FeedDestination) {
        guard isAtRoot, let container else { return }

        guard container.size != .full else {
            push(destination)
            return
        }

        pendingDestination = destination
        withAnimation {
            container.expand()
        }
    }

    func pop() {
        _ = path.popLast()
    }

    func selectTab(_ kind: FeedTabKind) {
        guard let tabs = rootViewModel?.tabsViewModel,
              let tab = tabs.tabs.first(where: { $0.kind == kind }) else { return }

        rootViewModel?.searchViewModel.reset()
        tabs.requestTabSelection(tab)
    }

    func present(_ destination: FeedDestination, onDismiss: (() -> Void)?) {
        endEditing()
        presentationDismissAction = onDismiss
        presented = destination
    }

    func presentFullScreen(_ destination: FeedDestination, zoomingFrom source: FeedZoomSource) {
        guard cover == nil else {
            return
        }

        endEditing()
        cover = FeedCover(destination: destination, zoomSource: source)
    }

    func dismissPresented() {
        if presented != nil {
            // Keep all follow-ups when another route closes before SwiftUI reports dismissal.
            if let presentationDismissAction {
                pendingPresentationDismissActions.append(presentationDismissAction)
            }
            presentationDismissAction = nil
        }

        presented = nil
        cover = nil
    }

    func presentModal(_ modal: FeedModal) {
        guard self.modal == nil else {
            return
        }

        endEditing()
        self.modal = modal
    }

    func dismissModal() {
        modal = nil
    }

    /// Resign before leaving the feed, otherwise UIKit restores the search field as first responder on the way back.
    private func endEditing() {
        UIApplication.shared.endEditing()
    }
}

// MARK: - Private

private extension FeedCoordinator {
    func bind(to container: any FeedContainer) {
        container
            .sizePublisher
            .withWeakCaptureOf(self)
            .sink { coordinator, size in
                if size != .full {
                    coordinator.pendingDestination = nil
                }

                // Keep search behind a child screen so Back can restore it after the sheet expands.
                guard size != .full, coordinator.path.isEmpty,
                      coordinator.presented == nil, coordinator.cover == nil else { return }

                coordinator.rootViewModel?.resetSavedScrollPositions()
                coordinator.rootViewModel?.searchViewModel.reset()
            }
            .store(in: &bag)

        container
            .dismissPublisher
            .withWeakCaptureOf(self)
            .sink { coordinator, _ in
                coordinator.dropRoutes()
            }
            .store(in: &bag)
    }

    /// Routes outlive a collapse — the collapsed sheet still shows the screen the user left open — but not the sheet
    /// itself: once it is gone, the screens it held go with it instead of living on until the main screen is rebuilt.
    func dropRoutes() {
        pendingDestination = nil
        guard path.isNotEmpty || presented != nil || cover != nil || modal != nil else {
            return
        }

        withTransaction(.withoutAnimations()) {
            path.removeAll()
            dismissPresented()
            modal = nil
            rootViewModel?.searchViewModel.reset()
        }
    }
}
