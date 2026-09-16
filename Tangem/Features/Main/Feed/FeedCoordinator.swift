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
            shtorkaStateObject.setNavigationActive(path.isNotEmpty)
        }
    }

    @Published var presented: FeedDestination?
    @Published var cover: FeedCover?

    let shtorkaStateObject = MainShtorkaStateObject()

    /// The feed's own views get the sheet narrowed down to what they may do with it, its view model to what it
    /// has to follow.
    var shtorkaReporting: any MainShtorkaReporting { shtorkaStateObject }
    var shtorkaActions: any MainShtorkaViewActionProvider { shtorkaStateObject }

    private var bag = Set<AnyCancellable>()

    required init(dismissAction: @escaping Action<Void>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        let context = FeedContext(navigation: self, popToRootAction: popToRootAction)
        rootViewModel = FeedViewModelFactory().makeViewModel(context: context, shtorkaActions: shtorkaActions)

        bind()
    }
}

// MARK: - Options

extension FeedCoordinator {
    struct Options {}
}

// MARK: - FeedNavigation

extension FeedCoordinator: FeedNavigation {
    func push(_ destination: FeedDestination) {
        endEditing()
        path.append(destination)
    }

    func pop() {
        _ = path.popLast()
    }

    func present(_ destination: FeedDestination) {
        endEditing()
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
        presented = nil
        cover = nil
    }

    /// Resign before leaving the feed, otherwise UIKit restores the search field as first responder on the way back.
    private func endEditing() {
        UIApplication.shared.endEditing()
    }
}

// MARK: - Sheet lifetime

private extension FeedCoordinator {
    func bind() {
        shtorkaStateObject
            .$isPresented
            .filter { !$0 }
            .withWeakCaptureOf(self)
            .sink { coordinator, _ in
                coordinator.dropRoutes()
            }
            .store(in: &bag)
    }

    /// Routes outlive a collapse — the collapsed sheet still shows the screen the user left open — but not the sheet
    /// itself: once it is gone, the screens it held go with it instead of living on until the main screen is rebuilt.
    func dropRoutes() {
        guard path.isNotEmpty || presented != nil || cover != nil else {
            return
        }

        withTransaction(.withoutAnimations()) {
            path.removeAll()
            presented = nil
            cover = nil
        }
    }
}
