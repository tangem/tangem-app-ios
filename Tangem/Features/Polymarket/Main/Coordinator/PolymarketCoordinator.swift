//
//  PolymarketCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

final class PolymarketCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root ViewModels

    @Published private(set) var rootViewModel: PolymarketMainViewModel?

    // MARK: - Init

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        let apiProvider = PolymarketAPIProviderFactory().makeProvider()
        rootViewModel = PolymarketMainViewModel(apiProvider: apiProvider, coordinator: self)
    }
}

extension PolymarketCoordinator {
    struct Options {}
}

// MARK: - PolymarketMainRoutable

extension PolymarketCoordinator: PolymarketMainRoutable {
    func dismiss() {
        dismissAction(())
    }
}
