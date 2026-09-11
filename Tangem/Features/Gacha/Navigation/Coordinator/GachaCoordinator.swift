//
//  GachaCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

final class GachaCoordinator: CoordinatorObject {
    // MARK: - Properties

    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Publishers

    @Published private(set) var state: ViewState?

    // MARK: - Init

    required init(dismissAction: @escaping Action<Void>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    // MARK: - Public methods

    func start(with options: Options) {
        switch options.destination {
        case .welcome:
            state = .welcome(GachaWelcomeViewModel(routable: self))
        case .main:
            state = .main(GachaMainViewModel())
        }
    }
}

// MARK: - Routables

extension GachaCoordinator: GachaWelcomeRoutable {
    func openStories() {
        state = .stories(GachaStoriesViewModel(routable: self))
    }
}

extension GachaCoordinator: GachaStoriesRoutable {
    func openMain() {
        state = .main(GachaMainViewModel())
    }
}

// MARK: - Nested types

extension GachaCoordinator {
    struct Options {
        let destination: Destination

        enum Destination {
            case welcome
            case main
        }
    }

    enum ViewState {
        case welcome(GachaWelcomeViewModel)
        case stories(GachaStoriesViewModel)
        case main(GachaMainViewModel)
    }
}
