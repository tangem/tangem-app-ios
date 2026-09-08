//
//  PolymarketOrderCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemPolymarket

final class PolymarketOrderCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root ViewModels

    @Published private(set) var viewModel: PolymarketOrderViewModel?
    @Published var slippageSelector: PolymarketSlippageSelectorViewModel?

    // MARK: - Init

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions> = { _ in }
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        Task { @MainActor in
            let model = PolymarketOrderModel(
                market: options.market,
                outcome: options.outcome,
                apiProvider: PolymarketAPIProviderFactory().makeProvider(),
                geoblockStateProvider: options.geoblockStateProvider,
                balancePublisher: options.balancePublisher
            )

            viewModel = PolymarketOrderViewModel(model: model, coordinator: self)
        }
    }
}

// MARK: - PolymarketOrderRoutable protocol conformance

extension PolymarketOrderCoordinator: PolymarketOrderRoutable {
    func closeOrder() {
        dismiss()
    }

    func openSlippageSelector(percent: Decimal, onConfirm: @escaping (Decimal) -> Void) {
        slippageSelector = PolymarketSlippageSelectorViewModel(percent: percent) { [weak self] confirmed in
            onConfirm(confirmed)
            self?.slippageSelector = nil
        }
    }
}

// MARK: - Options

extension PolymarketOrderCoordinator {
    struct Options {
        let market: PolymarketMarket
        let outcome: PolymarketOutcome
        let geoblockStateProvider: PolymarketGeoblockStateProvider
        let balancePublisher: AnyPublisher<Decimal?, Never>
    }
}
