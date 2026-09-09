//
//  CollectiblesCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

final class CollectiblesCoordinator: CoordinatorObject {
    // MARK: - Properties

    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Publishers

    @Published private(set) var state: ViewState?
    @Published var machineViewModel: CollectiblesMachineViewModel?

    // MARK: - Init

    required init(dismissAction: @escaping Action<Void>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    // MARK: - Public methods

    func start(with options: Options) {
        switch options.destination {
        case .welcome:
            state = .welcome(CollectiblesWelcomeViewModel(routable: self))
        case .main:
            Task { @MainActor [weak self] in
                guard let self else { return }
                state = .main(CollectiblesMainViewModel(routable: self))
            }
        }
    }
}

// MARK: - Routables

extension CollectiblesCoordinator: CollectiblesWelcomeRoutable {
    func openStories() {
        state = .stories(CollectiblesStoriesViewModel(routable: self))
    }
}

extension CollectiblesCoordinator: CollectiblesStoriesRoutable {
    func openMain() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            state = .main(CollectiblesMainViewModel(routable: self))
        }
    }
}

extension CollectiblesCoordinator: CollectiblesMainRoutable {
    func openMachine(for pack: CollectiblesPack) {
        guard machineViewModel == nil else { return }

        machineViewModel = CollectiblesMachineViewModel(pack: pack)
    }
}

// MARK: - Nested types

extension CollectiblesCoordinator {
    struct Options {
        let destination: Destination

        enum Destination {
            case welcome
            case main
        }
    }

    enum ViewState {
        case welcome(CollectiblesWelcomeViewModel)
        case stories(CollectiblesStoriesViewModel)
        case main(CollectiblesMainViewModel)
    }
}
