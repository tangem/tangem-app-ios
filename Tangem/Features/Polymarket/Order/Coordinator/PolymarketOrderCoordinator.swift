//
//  PolymarketOrderCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPolymarket

final class PolymarketOrderCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root ViewModels

    @Published private(set) var viewModel: PolymarketOrderViewModel?

    // MARK: - Init

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions> = { _ in }
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        viewModel = PolymarketOrderViewModel(
            market: options.market,
            outcome: options.outcome,
            coordinator: self
        )
    }
}

// MARK: - PolymarketOrderRoutable protocol conformance

extension PolymarketOrderCoordinator: PolymarketOrderRoutable {
    func closeOrder() {
        dismiss()
    }
}

// MARK: - Options

extension PolymarketOrderCoordinator {
    struct Options {
        let market: PolymarketMarket
        let outcome: PolymarketOutcome
    }
}
