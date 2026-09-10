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
    @Published var path: [FeedDestination] = []
    @Published var presented: FeedDestination?

    let shtorkaStateObject = MainShtorkaStateObject()

    private var bag = Set<AnyCancellable>()

    required init(dismissAction: @escaping Action<Void>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        let context = FeedContext(navigation: self, popToRootAction: popToRootAction)
        rootViewModel = FeedViewModelFactory().makeViewModel(context: context)

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
        // Resign before the push, otherwise UIKit restores the search field as first responder on the way back.
        UIApplication.shared.endEditing()
        path.append(destination)
    }

    func pop() {
        _ = path.popLast()
    }

    func present(_ destination: FeedDestination) {
        presented = destination
    }

    func dismiss(id: FeedDestination.ID) {
        guard presented?.id == id else {
            return
        }

        presented = nil
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
        guard path.isNotEmpty || presented != nil else {
            return
        }

        withTransaction(.withoutAnimations()) {
            path.removeAll()
            presented = nil
        }
    }
}
